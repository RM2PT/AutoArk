package com.rm2pt.generator.autoark

import arkuimodel.arkUIModel.Event
import arkuimodel.arkUIModel.TextInputWidget

class EventGenerator {
	PageInformation info
	String onClick

	new(Event event, PageInformation info) {
		this.info = info
		onClick = event.onClick
		if (onClick !== null) {
			var flow = info.root.getFlow(onClick)
			if (flow !== null && flow.workFlowCode === null) {
				flow.generateWorkFlow
			}
		}
	}

	def getInfo() { return info }

	// TODO: function may have parameters
	def eventCode() '''
		«componentEvent»
		«IF onClick !== null»
			.onClick(() => { this.«onClick»(«info.paramsAssign») })
		«ENDIF»
	'''

	def componentEvent() ''''''
}

class TextInputEventGenerator extends EventGenerator {
	String text
	String onChange

	new(TextInputWidget input, PageInformation info) {
		super(input.textinputevent, info)
		text = info.findValue(input.text)
		onChange = input.textinputevent.onChange
	}

	override componentEvent() '''
		«IF text !== null && onChange === null»
			.onChange((value: string) => { «text» = value })
		«ELSE»
			.onChange(() => { this.«onChange»(«info.paramsAssign») })
		«ENDIF»
	'''
}
