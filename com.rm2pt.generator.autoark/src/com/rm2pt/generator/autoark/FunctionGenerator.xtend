package com.rm2pt.generator.autoark

import java.util.ArrayList
import java.util.List

import arkuimodel.arkUIModel.CaseOp
import arkuimodel.arkUIModel.ChangeIndex
import arkuimodel.arkUIModel.Expression
import arkuimodel.arkUIModel.Function
import arkuimodel.arkUIModel.HttpOperation
import arkuimodel.arkUIModel.OpenDialog
import arkuimodel.arkUIModel.Parameter
import arkuimodel.arkUIModel.RouteSkip
import arkuimodel.arkUIModel.SetParameter
import arkuimodel.arkUIModel.ShowToastOptions
import arkuimodel.arkUIModel.WorkFlow
import arkuimodel.arkUIModel.GetRouteValue
import arkuimodel.arkUIModel.GetParameter
import arkuimodel.arkUIModel.CloseDialog

abstract class FunctionGenerator {
	Function func
	WorkFlow flow
	PageInformation info

	new(Function func, WorkFlow flow, PageInformation info) {
		this.func = func
		this.flow = flow
		this.info = info
	}

	def getFunc() { return func }

	def getFlow() { return flow }

	def getInfo() { return info }

	def String functionCode()
}

class SetParameterGenerator extends FunctionGenerator {
	String key
	String value

	new(Function func, WorkFlow flow, PageInformation info) {
		super(func, flow, info)
		var op = func.operation as SetParameter
		key = info.findValue(op.parm)
		value = info.findValue(op.value)
	}

	override functionCode() '''
		«key» = «value»;
		«WorkFlowGenerator.sequenceCode(func, flow, info)»
	'''
}

class GetParameterGenerator extends FunctionGenerator {
	String type
	String key
	String value

	new(Function func, WorkFlow flow, PageInformation info) {
		super(func, flow, info)
		var op = func.operation as GetParameter
		type = op.name !== null ? op.name : "any"
		key = op.parm
		value = info.findValue(op.value)
	}

	override functionCode() '''
		let «key» = «value»;
		«sequenceCode»
	'''

	def sequenceCode() {
		var variable = new ArkUIVariable(key, type, VariableDeclaration.LOCAL)
		info.addVariable(variable)
		var sequenceCode = WorkFlowGenerator.sequenceCode(func, flow, info)
		info.removeVariable(variable)
		return sequenceCode
	}
}

class ShowToastGenerator extends FunctionGenerator {
	String msg

	new(Function func, WorkFlow flow, PageInformation info) {
		super(func, flow, info)
		var op = func.operation as ShowToastOptions
		msg = info.findValue(op.message)
		info.addImport('prompt', '"@ohos.prompt"')
	}

	override functionCode() '''
		prompt.showToast({ «IF msg !== null»message: «msg»,«ENDIF» })
		«WorkFlowGenerator.sequenceCode(func, flow, info)»
	'''
}

class HttpOperationGenerator extends FunctionGenerator {
	String url
	String httpType
	String res
	Parameter[] params

	new(Function func, WorkFlow flow, PageInformation info) {
		super(func, flow, info)
		var op = func.operation as HttpOperation
		url = info.findValue(op.url)
		httpType = op.httpType
		res = op.res
		params = op.contains
		info.addImport('http', '"@ohos.net.http"')
	}

	override functionCode() '''
		let «func.name» = http.createHttp()
		«func.name».request(
			"«info.backendURL»" + «url», {
				method: http.RequestMethod.«httpType»,
				header: { "Content-Type": "application/json" },
				extraData: {
					«FOR param : params»
						«param.name»: «info.findValue(param.value)»,
					«ENDFOR»
				},
				connectTimeout: 60000,
				readTimeout: 60000,
			}
		).then((value) => {
			let «res» = JSON.parse(String(value.result))
			«resolveCode»
		})
	'''

	def resolveCode() {
		var variable = new ArkUIVariable(res, "any", VariableDeclaration.LOCAL)
		info.addVariable(variable)
		var sequenceCode = WorkFlowGenerator.sequenceCode(func, flow, info)
		info.removeVariable(variable)
		return sequenceCode
	}
}

class ChangeIndexGenerator extends FunctionGenerator {
	String controller
	String index

	new(Function func, WorkFlow flow, PageInformation info) {
		super(func, flow, info)
		var op = func.operation as ChangeIndex
		controller = info.findValue('''${«op.tabsID»Controller}''')
		index = info.findValue(op.tabID)
	}

	override functionCode() '''
		«controller».changeIndex(«index»)
		«WorkFlowGenerator.sequenceCode(func, flow, info)»
	'''
}

class RouteSkipGenerator extends FunctionGenerator {
	RouteSkip op
	PageInformation info
	String type
	String dest

	new(Function func, WorkFlow flow, PageInformation info) {
		super(func, flow, info)
		op = func.operation as RouteSkip
		this.info = info
		type = op.type
		dest = op.page
		info.root.addImport('router', '"@ohos.router"')
	}

	def routeParams() '''
		params: {
			«FOR param : op.contains»
				«param.name»: «info.findValue(param.value)»,
			«ENDFOR»
		}
	'''

	override functionCode() '''
		router.«type»({ url: "pages/«dest»"«IF op.contains.size > 0», «routeParams»«ENDIF» })
		«WorkFlowGenerator.sequenceCode(func, flow, info)»
	'''
}

class GetRouteValueGenerator extends FunctionGenerator {
	GetRouteValue op
	PageInformation info
	String name
	String variableName
	ArkUIVariable variable

	new(Function func, WorkFlow flow, PageInformation info) {
		super(func, flow, info)
		op = func.operation as GetRouteValue
		this.info = info
		name = op.name
		variableName = op.variable
		variable = new ArkUIVariable(variableName, "string", VariableDeclaration.LOCAL)
		info.addVariable(variable)
		info.root.addImport('router', '"@ohos.router"')
	}

	override functionCode() {
		var funcCode = '''
			var «variableName» = router.getParams()['«name»']
			«WorkFlowGenerator.sequenceCode(func, flow, info)»
		'''
		info.removeVariable(variable)
		return funcCode
	}
}

class OpenDialogGenerator extends FunctionGenerator {
	String title
	String msg
	String assignDialog
	String dialogCode

	new(Function func, WorkFlow flow, PageInformation info) {
		super(func, flow, info)
		var op = func.operation as OpenDialog
		assignDialog = op.assignDialog
		if (assignDialog !== null) {
			dialogCode = customDialogCode
		} else {
			for (param : op.contains) {
				switch param.name {
					case "title": title = info.findValue(param.value)
					case "message": msg = info.findValue(param.value)
				}
			}
			info.addImport('prompt', '"@ohos.prompt"')
			dialogCode = promptDialogCode
		}
	}

	def String promptDialogCode() '''
		prompt.showDialog({
			«IF title !== null»title: «title»,«ENDIF»
			«IF msg !== null»message: «msg»,«ENDIF»
		})
		«WorkFlowGenerator.sequenceCode(func, flow, info)»
	'''

	def String customDialogCode() '''
		this.«assignDialog»Controller.open()
	'''

	override functionCode() {
		return dialogCode
	}
}

class CloseDialogGenerator extends FunctionGenerator {
	String assignDialog

	new(Function func, WorkFlow flow, PageInformation info) {
		super(func, flow, info)
		var op = func.operation as CloseDialog
		assignDialog = op.assignDialog
	}

	override functionCode() '''
		this.«assignDialog»Controller.close()
	'''
}

class CaseGenerator extends FunctionGenerator {
	List<ArkUIVariable> variables = new ArrayList
	List<Pair<Expression, String>> exps = new ArrayList

	new(Function func, WorkFlow flow, PageInformation info) {
		super(func, flow, info)
		var op = func.operation as CaseOp
		for (exp : op.expression) {
			var flag = info.findValue(exp.expressText)
			var variable = new ArkUIVariable(exp.name, "boolean", VariableDeclaration.LOCAL)
			variables.add(variable)
			info.addVariable(variable)
			exps.add(exp -> flag)
		}
	}

	override functionCode() {
		var caseCode = '''
			«FOR entry : exps»
				let «entry.key.name» = «entry.value»
			«ENDFOR»
			«FOR entry : exps»
				if («entry.key.name») {
					«WorkFlowGenerator.conditionCode(func, entry.key, flow, info)»
				}
			«ENDFOR»
		'''
		for (variable : variables) {
			info.removeVariable(variable)
		}
		return caseCode
	}
}
