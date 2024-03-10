package com.rm2pt.generator.autoark

import java.util.ArrayList
import java.util.List

import org.eclipse.xtext.generator.IFileSystemAccess2

import arkuimodel.arkUIModel.Page
import arkuimodel.arkUIModel.StyleLibray
import arkuimodel.arkUIModel.OperationLibray

class ProjectGenerator {
	IFileSystemAccess2 fsa
	MyInfoWizard wizard
	StyleLibray styleLib
	OperationLibray opLib
	Page[] uiPages
	List<PageGenerator> pages = new ArrayList

	def setFsa(IFileSystemAccess2 fsa) { this.fsa = fsa }

	def setWizard(MyInfoWizard wizard) { this.wizard = wizard }

	def setStyleLib(StyleLibray styleLib) { this.styleLib = styleLib }

	def setOpLib(OperationLibray opLib) {
		this.opLib = opLib
		fsa.generateFile("entry/src/main/ets/MainAbility/constants/CommonConstants.ets", globalConstants)
	}

	def findStyle(String styleName) {
		for (style : styleLib.styleclass) {
			if (style.name == styleName) {
				return style
			}
		}
	}

	def getGlobalParams() {
		return opLib.projectparameters
	}

	def getUIPages() { return uiPages }

	def setUIPages(Page[] uiPages) { this.uiPages = uiPages }

	def PageGenerator[] getPages() { return pages }

	def addPage(PageGenerator page) { pages.add(page) }

	def clearPages() { pages.clear }

	def PageGenerator[] getEntries() {
		var List<PageGenerator> entries = new ArrayList
		for (page : pages) {
			if (page.isEntry) {
				entries.add(page)
			}
		}
		return entries
	}

	def generateFile(String fileName, CharSequence contents) { fsa.generateFile(fileName, contents) }

	def getBackendURL() { return wizard.backendURL }

	def getAPIVersion() { return wizard.APIVersion }

	def getProjectName() { return wizard.projectName }

	def globalConstants() '''
		export default class CommonConstants {
			«FOR param : globalParams»
				static readonly «param.name» = «param.value»;
			«ENDFOR»
		}
	'''
}
