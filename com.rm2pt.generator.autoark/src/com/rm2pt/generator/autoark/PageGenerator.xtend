package com.rm2pt.generator.autoark

import java.util.regex.Pattern

import arkuimodel.arkUIModel.Page
import arkuimodel.arkUIModel.PageStruct
import arkuimodel.arkUIModel.Parameter
import arkuimodel.arkUIModel.UILogic
import arkuimodel.arkUIModel.PageRefrence

class PageGenerator {
	Page uiPage
	PageStruct uiRoot
	UILogic uiLogic
	PageInformation info
	boolean isEntry = true
	boolean hasFile = false

	new(Page uiPage, ProjectGenerator project) {
		this.uiPage = uiPage
		uiRoot = uiPage.uidesign.pageview
		uiLogic = uiPage.uilogic
		info = new PageInformation(project, uiLogic)
	}

	def getIsEntry() { return isEntry }

	def Page[] getSubPages() { return uiPage.subpages }

	def checkSubPage(Page[] subPages) {
		for (uiPage : subPages) {
			if (uiPage == this.uiPage) {
				isEntry = false
			}
		}
	}

	def getPageTitle() { return uiPage.pageTitle }

	def String pageCode(Boolean isDialog) {
		if (isDialog) {
			info.addVariable(new ArkUIVariable("selfController", "CustomDialogController", VariableDeclaration.PRIVATE))
		}
		for (flow : uiLogic.workflow) {
			info.addFlow(new WorkFlowGenerator(flow, info))
		}
		var buildCode = if (uiRoot.widgets.size > 1) {
				throw new Exception("There can be only one root component for page: " + pageTitle)
			} else if (uiRoot.widgets.size == 1) {
				ComponentGenerator.generateComponent(uiRoot.widgets.get(0), info)
			}
		var structCode = '''
			«IF isEntry»@Entry«ENDIF»
			«IF isDialog»@CustomDialog«ELSE»@Component«ENDIF»
			«IF !isEntry»export default «ENDIF»struct «uiRoot.title» {
				«FOR variable : info.variables AFTER '\n'»
					«variable.field»
				«ENDFOR»
				«aboutToAppear»
				«FOR builder : info.builders SEPARATOR "\n" AFTER '\n'»
					«builder.builderCode»
				«ENDFOR»
				«FOR flow : info.flows SEPARATOR "\n" AFTER '\n'»
					«flow.workFlowCode»
				«ENDFOR»
				build() {
					«buildCode»
				}
			}
		'''
		return '''
			«FOR entry : info.imports AFTER '\n'»
				import «entry.key» from «entry.value»
			«ENDFOR»
			«FOR style : info.styles SEPARATOR "\n" AFTER '\n'»
				«style.stylePrefix» function «style.name»() {
					«style.styleCode»
				}
			«ENDFOR»
			«structCode»
		'''
	}

	def generatePage(Boolean isDialog) {
		if (!hasFile) {
			info.generateFile("entry/src/main/ets/MainAbility/pages/" + pageTitle + ".ets", pageCode(isDialog))
			hasFile = true
		}
	}

	def aboutToAppear() {
		if (uiRoot.pageevent.aboutToAppear !== null) {
			for (flow : info.flows) {
				if (flow.workFlowName == uiRoot.pageevent.aboutToAppear) {
					flow.generateWorkFlow
					return '''
						aboutToAppear() {
							this.«flow.workFlowName»()
						}
						
					'''
				}
			}
		}
	}

	def findParameter(Parameter param, PageInformation info) {
		var variable = this.info.findVariable(param.name)
		if (variable.decl == VariableDeclaration.PROP || variable.decl == VariableDeclaration.LINK) {
			var regex = "(?<=\\$\\{)\\S+(?=\\})"
			var matcher = Pattern.compile(regex).matcher(param.value)
			if (matcher.find)
				'''«param.name»: $«matcher.group»'''
			else
				throw new Exception("Undefined Assignment: " + param.name)
		} else
			'''«param.name»: «info.findValue(param.value)»'''
	}

	def ifReference(PageRefrence ref, PageInformation info) {
		if (ref.getIf !== null) {
			var exp = info.findValue(ref.getIf.autoExpression)
			return '''
				if («exp») {
					«forEachReference(ref, info)»
				}
			'''
		} else {
			return forEachReference(ref, info)
		}
	}

	def forEachReference(PageRefrence ref, PageInformation info) {
		var componentCode = '''«ref.name»(«IF ref.parameter.size > 0»{«FOR param : ref.parameter SEPARATOR ', '»«findParameter(param, info)»«ENDFOR»}«ENDIF»)'''
		if (ref.foreach !== null) {
			var arr = info.findValue('''${«ref.foreach.array»}''')
			var type = ref.foreach.arrayType
			var item = ref.foreach.item
			var variable = new ArkUIVariable(item, type, item, VariableDeclaration.LOCAL)
			info.addVariable(variable)
			var forEachCode = '''
				ForEach(«arr», («item»: «type») => {
					«componentCode»
				})
			'''
			info.removeVariable(variable)
			return forEachCode
		} else {
			return componentCode
		}
	}
}
