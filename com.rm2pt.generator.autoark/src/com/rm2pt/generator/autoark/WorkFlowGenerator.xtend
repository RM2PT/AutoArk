package com.rm2pt.generator.autoark

import arkuimodel.arkUIModel.CaseOp
import arkuimodel.arkUIModel.ChangeIndex
import arkuimodel.arkUIModel.EndOp
import arkuimodel.arkUIModel.Expression
import arkuimodel.arkUIModel.Function
import arkuimodel.arkUIModel.HttpOperation
import arkuimodel.arkUIModel.LineType
import arkuimodel.arkUIModel.OpenDialog
import arkuimodel.arkUIModel.RouteSkip
import arkuimodel.arkUIModel.SetParameter
import arkuimodel.arkUIModel.ShowToastOptions
import arkuimodel.arkUIModel.StartOp
import arkuimodel.arkUIModel.WorkFlow
import arkuimodel.arkUIModel.GetRouteValue
import arkuimodel.arkUIModel.GetParameter
import arkuimodel.arkUIModel.CloseDialog

class WorkFlowGenerator {
	WorkFlow flow
	PageInformation info
	CharSequence workFlowCode

	new(WorkFlow flow, PageInformation info) {
		this.flow = flow
		this.info = info
	}

	def getWorkFlowName() { return flow.flowName }

	def getWorkFlowCode() { return workFlowCode }

	// TODO: function may have parameters
	def generateWorkFlow() {
		workFlowCode = '''
			«flow.flowName»(«info.paramsDecl») {
				«sequenceCode(start, flow, info)»
			}
		'''
	}

	def getStart() {
		for (func : flow.function) {
			if (func.operation instanceof StartOp) {
				return func
			}
		}
	}

	def static findFunction(Function func, WorkFlow flow, PageInformation info) {
		return switch func.operation {
			SetParameter: new SetParameterGenerator(func, flow, info)
			GetParameter: new GetParameterGenerator(func, flow, info)
			ShowToastOptions: new ShowToastGenerator(func, flow, info)
			HttpOperation: new HttpOperationGenerator(func, flow, info)
			ChangeIndex: new ChangeIndexGenerator(func, flow, info)
			RouteSkip: new RouteSkipGenerator(func, flow, info)
			GetRouteValue: new GetRouteValueGenerator(func, flow, info)
			OpenDialog: new OpenDialogGenerator(func, flow, info)
			CloseDialog: new CloseDialogGenerator(func, flow, info)
			CaseOp: new CaseGenerator(func, flow, info)
			StartOp,
			EndOp: null
			default: throw new Exception("Undefined UI Function: " + func.class.name)
		}
	}

	def static generateFunction(Function func, WorkFlow flow, PageInformation info) {
		var generator = findFunction(func, flow, info)
		return generator !== null ? generator.functionCode : ''''''
	}

	def static sequenceCode(Function func, WorkFlow flow, PageInformation info) {
		for (line : flow.flowline) {
			if (line.source == func && line.type == LineType.SEQUENCE) {
				return generateFunction(line.target, flow, info)
			}
		}
	}

	def static conditionCode(Function func, Expression exp, WorkFlow flow, PageInformation info) {
		for (line : flow.flowline) {
			if (line.source == func && line.type == LineType.CONDITION && line.value == exp.name) {
				return generateFunction(line.target, flow, info)
			}
		}
	}
}
