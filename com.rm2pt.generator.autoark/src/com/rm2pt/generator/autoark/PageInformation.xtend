package com.rm2pt.generator.autoark

import java.util.ArrayList
import java.util.HashMap
import java.util.List
import java.util.Map
import java.util.regex.Pattern

import arkuimodel.arkUIModel.Array
import arkuimodel.arkUIModel.PageRefrence
import arkuimodel.arkUIModel.TypeCS
import arkuimodel.arkUIModel.UILogic

class PageInformation {
	ProjectGenerator project
	PageInformation parent
	List<ArkUIVariable> variables = new ArrayList
	Map<String, String> imports = new HashMap
	List<BuilderGenerator> builders = new ArrayList
	List<WorkFlowGenerator> flows = new ArrayList
	List<StyleGenerator> styles = new ArrayList

	new(ProjectGenerator project, UILogic uiLogic) {
		this.project = project
		for (param : uiLogic.pageparameter) {
			var type = findType(param.type)
			var variable = if (type == "CustomDialogController") {
					new ArkUIVariable(param.name, type, findValue(param.value), VariableDeclaration.PRIVATE)
				} else if (param.value !== null) {
					new ArkUIVariable(param.name, type, findValue(param.value), VariableDeclaration.STATE)
				} else {
					// TODO: have to decide whether to use PROP or LINK here
					new ArkUIVariable(param.name, type, VariableDeclaration.LINK)
				}
			addVariable(variable)
		}
		imports.put("CommonConstants", "'../constants/CommonConstants'")
	}

	new(PageInformation info, UILogic uiLogic, PageRefrence ref) {
		this.parent = info
		this.project = info.project
		for (param : uiLogic.pageparameter) {
			for (refParam : ref.parameter) {
				if (refParam.name == param.name) {
					var type = findType(param.type)
					var variable = new ArkUIVariable(param.name, type, refParam.value, VariableDeclaration.LOCAL)
					addVariable(variable)
				}
			}
		}
	}

	def void generateFile(String fileName, CharSequence contents) { project.generateFile(fileName, contents) }

	def getBackendURL() { return project.backendURL }

	def getAPIVersion() { return project.APIVersion }

	def findUIPage(String pageName) {
		for (uiPage : project.UIPages) {
			if (uiPage.pageTitle == pageName) {
				return uiPage
			}
		}
		throw new Exception("Undefined UI Page: " + pageName)
	}

	def getPages() { return project.pages }

	def getRoot() {
		var root = this
		while (root.parent !== null) {
			root = root.parent
		}
		return root
	}

	def ArkUIVariable[] getVariables() { return variables }

	def addVariable(ArkUIVariable variable) { variables.add(variable) }

	def removeVariable(ArkUIVariable variable) { variables.remove(variable) }

	def getImports() { return imports.entrySet }

	def addImport(String key, String value) { imports.put(key, value) }

	def BuilderGenerator[] getBuilders() { return builders }

	def addBuilder(BuilderGenerator builder) { builders.add(builder) }

	def hasBuilder(String name) {
		for (builder : builders) {
			if (builder.builderName == name) {
				return true
			}
		}
		return false
	}

	def String findType(TypeCS type) {
		if (type instanceof Array) {
			return '''Array<«findType(type.atype)»>'''
		} else {
			return switch type.type {
				case "string": "string"
				case "number": "number"
				case "boolean": "boolean"
				case "Resource": "Resource"
				case "CustomDialogController": "CustomDialogController"
				default: importEntity(type.type)
			}
		}
	}

	def importEntity(String type) {
		imports.put('''{ «type» }''', '''"../common/«type»"''')
		return type
	}

	def isNumber(String str) {
		var regex = "^\\d+$"
		var matcher = Pattern.compile(regex).matcher(str)
		return matcher.find
	}

	def isWord(String str) {
		var regex = "^[ !#%\\-./\\w]+$"
		var matcher = Pattern.compile(regex).matcher(str)
		return matcher.find
	}

	def findName(String str) {
		var regex = "(?<=\\$\\{)\\S+?(?=\\})"
		var matcher = Pattern.compile(regex).matcher(str)
		return matcher.find ? matcher.group : null
	}

	def ArkUIVariable findVariable(String name) {
		for (variable : variables) {
			if (variable.name == name) {
				return variable
			}
		}
		if (parent !== null) {
			return parent.findVariable(name)
		} else {
			for (param : project.globalParams) {
				if (param.name == name) {
					return new ArkUIVariable(param.name, findType(param.type), param.value, VariableDeclaration.GLOBAL)
				}
			}
			throw new Exception("Variable does not exist: " + name)
		}
	}

	def findValue(String str) {
		if (str === null) {
			return null
		} else if (str == "false" || str == "true" || str == "undefined") {
			return str
		} else if (isNumber(str)) {
			return str
		} else if (isWord(str)) {
			return '''"«str»"'''
		} else {
			var value = str
			var String name
			while ((name = findName(value)) !== null) {
				value = Pattern.compile("\\$\\{" + name + "\\}").matcher(value).replaceAll(findVariable(name).assign)
			}
			return value
		}
	}

	def List<ArkUIVariable> getLocals() {
		var List<ArkUIVariable> locals = new ArrayList
		for (variable : variables) {
			if (variable.decl == VariableDeclaration.LOCAL) {
				locals.add(variable)
			}
		}
		if (parent !== null) {
			locals.addAll(parent.locals)
		}
		return locals
	}

	def paramsDecl() '''«FOR variable : locals SEPARATOR ', '»«variable.name»: «variable.type»«ENDFOR»'''

	def paramsAssign() '''«FOR variable : locals SEPARATOR ', '»«variable.assign»«ENDFOR»'''

	def paramsValue() '''«FOR variable : locals SEPARATOR ', '»«findValue(variable.init)»«ENDFOR»'''

	def getFlows() { return flows }

	def addFlow(WorkFlowGenerator flow) { flows.add(flow) }

	def getFlow(String name) {
		for (flow : flows) {
			if (flow.workFlowName == name) {
				return flow
			}
		}
		return null
	}

	def StyleGenerator[] getStyles() { return styles }

	def hasStyle(String styleName) {
		for (style : styles) {
			if (style.name == styleName) {
				return true
			}
		}
		return false
	}

	def findStyle(String styleName) { return project.findStyle(styleName) }

	def addStyle(StyleGenerator style) { styles.add(style) }
}
