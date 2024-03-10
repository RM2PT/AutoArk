package com.rm2pt.generator.autoark

import arkuimodel.arkUIModel.PageStruct
import arkuimodel.arkUIModel.UIComponent

class BuilderGenerator {
	PageInformation info
	CharSequence builderCode
	String builderName

	new(UIComponent component, PageInformation info) {
		if (component.widget.size == 0 && component.pagerefrence.size == 1) {
			var ref = component.pagerefrence.get(0)
			var page = info.findUIPage(ref.name)
			var root = info.root
			this.info = new PageInformation(info, page.uilogic, ref)
			for (flow : page.uilogic.workflow) {
				root.addFlow(new WorkFlowGenerator(flow, this.info))
			}
			builderName = page.uidesign.pageview.title
			builderCode = complexBuilder(page.uidesign.pageview)
		} else {
			this.info = info
			builderName = component.id
			builderCode = simpleBuilder(component)
		}
	}

	def simpleBuilder(UIComponent component) '''
		@Builder «builderName»(«info.paramsDecl») {
			«FOR sub : component.widget»
				«ComponentGenerator.generateComponent(sub, info)»
			«ENDFOR»
			«FOR ref : component.pagerefrence»
				«ComponentGenerator.findReference(ref, info, false)»
			«ENDFOR»
		}
	'''

	def complexBuilder(PageStruct uiRoot) '''
		@Builder «builderName»(«info.paramsDecl») {
			«FOR sub : uiRoot.widgets»
				«ComponentGenerator.generateComponent(sub, info)»
			«ENDFOR»
		}
	'''

	def getBuilderName() { return builderName }

	def getBuilderCode() { return builderCode }

	def getReferenceCode() '''this.«builderName»(«info.paramsValue»)'''
}
