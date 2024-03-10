package com.rm2pt.generator.autoark

class ArkUIVariable {
	String name
	String type
	String init
	VariableDeclaration decl

	new(String name, String type, VariableDeclaration decl) {
		this.name = name
		this.type = type
		this.decl = decl
	}

	new(String name, String type, String init, VariableDeclaration decl) {
		this.name = name
		this.type = type
		this.init = init
		this.decl = decl
	}

	def getName() { return name }

	def getType() { return type }

	def getInit() { return init }

	def getDecl() { return decl }

	def getPrefix() {
		return switch decl {
			case STATE: "@State"
			case PROP: "@Prop"
			case LINK: "@Link"
			case PRIVATE: "private"
			default: throw new Exception("Undefined Field Variable: " + name)
		}
	}

	def getAssign() {
		return switch decl {
			case STATE,
			case PROP,
			case LINK,
			case PRIVATE: "this." + name
			case LOCAL: name
			case GLOBAL: "CommonConstants." + name
		}
	}

	def getField() '''«prefix» «name»: «type»«IF init !== null» = «init»«ENDIF»'''
}

enum VariableDeclaration {
	STATE,
	PROP,
	LINK,
	PRIVATE,
	LOCAL,
	GLOBAL
}
