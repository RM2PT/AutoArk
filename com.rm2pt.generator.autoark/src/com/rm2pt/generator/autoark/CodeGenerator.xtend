package com.rm2pt.generator.autoark

import org.eclipse.emf.ecore.resource.Resource
import org.eclipse.xtext.generator.AbstractGenerator
import org.eclipse.xtext.generator.IFileSystemAccess2
import org.eclipse.xtext.generator.IGeneratorContext

import arkuimodel.arkUIModel.Array
import arkuimodel.arkUIModel.Entity
import arkuimodel.arkUIModel.GUIModel
import arkuimodel.arkUIModel.TypeCS

class CodeGenerator extends AbstractGenerator {
	ProjectGenerator project = new ProjectGenerator

	def setWizard(MyInfoWizard wizard) { project.wizard = wizard }

	override doGenerate(Resource resource, IFileSystemAccess2 fsa, IGeneratorContext context) {
		project.fsa = fsa
		var guiModel = resource.getEObject("/") as GUIModel
		project.styleLib = guiModel.stylelibray
		project.opLib = guiModel.operationlibray
		project.UIPages = guiModel.rootpage.page
		project.clearPages
		for (uiPage : project.UIPages) {
			var page = new PageGenerator(uiPage, project)
			project.addPage(page)
		}
		for (src : project.pages) {
			for (dest : project.pages) {
				dest.checkSubPage(src.subPages)
			}
		}
		for (page : project.pages) {
			if (page.isEntry) {
				page.generatePage(false)
			}
		}
		for (entity : guiModel.operationlibray.domainmodel.entity) {
			fsa.generateFile("entry/src/main/ets/MainAbility/common/" + entity.name + ".ets", entityEts(entity))
		}
		fsa.generateFile("entry/src/main/ets/MainAbility/app.ets", appEts)
		fsa.generateFile("entry/src/main/resources/base/element/string.json", stringJson)
		fsa.generateFile("entry/src/main/config.json", configJson)
		fsa.generateFile("entry/build-profile.json5", entryBuildProfileJson5)
		fsa.generateFile("entry/hvigorfile.ts", entryHvigorfileTs)
		fsa.generateFile("entry/package.json", entryPackageJson)
		fsa.generateFile("build-profile.json5", buildProfileJson5)
		fsa.generateFile("hvigorfile.ts", hvigorfileTs)
		fsa.generateFile("package.json", packageJson)
		System.out.println("Successfully generate " + project.projectName + "!")
	}

	def entityEts(Entity entity) '''
		export class «entity.name» {
			«FOR attr : entity.attributes»
				«attr.name»: «findType(attr.type)»
			«ENDFOR»
			
			constructor(«FOR attr : entity.attributes SEPARATOR ', '»«attr.name»: «findType(attr.type)»«ENDFOR») {
				«FOR attr : entity.attributes»
					this.«attr.name» = «attr.name»
				«ENDFOR»
			}
		}
	'''

	def String findType(TypeCS type) {
		if (type instanceof Array) {
			return "Array<" + findType(type.atype) + ">"
		} else {
			return switch type.type {
				case "string": "string"
				case "number": "number"
				case "resource": "Resource"
				default: type.type
			}
		}
	}

	def appEts() '''
		import hilog from '@ohos.hilog';
		
		export default {
		  onCreate() {
		    hilog.info(0x0000, 'testTag', '%{public}s', 'Application onCreate');
		  },
		  onDestroy() {
		    hilog.info(0x0000, 'testTag', '%{public}s', 'Application onDestroy');
		  },
		}
	'''

	def stringJson() '''
		{
		  "string": [
		    {
		      "name": "module_desc",
		      "value": "module description"
		    },
		    {
		      "name": "MainAbility_desc",
		      "value": "description"
		    },
		    {
		      "name": "MainAbility_label",
		      "value": "label"
		    }
		  ]
		}
	'''

	def configJson() '''
		{
		  "app": {
		    "bundleName": "com.example.myapplication",
		    "vendor": "example",
		    "version": {
		      "code": 1000000,
		      "name": "1.0.0"
		    }
		  },
		  "deviceConfig": {
		  	"default": {
		  	  "network": {
		  	  	"cleartextTraffic": true
		  	  }
		  	}
		  },
		  "module": {
		    "package": "com.example.myapplication",
		    "name": ".entry",
		    "mainAbility": ".MainAbility",
		    "deviceType": [
		      "phone",
		      "tablet"
		    ],
		    "distro": {
		      "deliveryWithInstall": true,
		      "moduleName": "entry",
		      "moduleType": "entry",
		      "installationFree": false
		    },
		    "abilities": [
		      {
		        "skills": [
		          {
		            "entities": [
		              "entity.system.home"
		            ],
		            "actions": [
		              "action.system.home"
		            ]
		          }
		        ],
		        "orientation": "unspecified",
		        "formsEnabled": false,
		        "name": ".MainAbility",
		        "srcLanguage": "ets",
		        "srcPath": "MainAbility",
		        "icon": "$media:icon",
		        "description": "$string:MainAbility_desc",
		        "label": "$string:MainAbility_label",
		        "type": "page",
		        "visible": true,
		        "launchType": "standard"
		      }
		    ],
		    "js": [
		      {
		        "mode": {
		          "syntax": "ets",
		          "type": "pageAbility"
		        },
		        "pages": [
		          «FOR page : project.entries SEPARATOR ",\n"»"pages/«page.pageTitle»"«ENDFOR»
		        ],
		        "name": ".MainAbility",
		        "window": {
		          "designWidth": 720,
		          "autoDesignWidth": false
		        }
		      }
		    ]
		  }
		}
	'''

	def entryBuildProfileJson5() '''
		{
		  "apiType": 'faMode',
		  "buildOption": {
		  },
		  "targets": [
		    {
		      "name": "default",
		      "runtimeOS": "HarmonyOS"
		    },
		    {
		      "name": "ohosTest",
		    }
		  ]
		}
	'''

	def entryHvigorfileTs() '''export { legacyHapTasks } from '@ohos/hvigor-ohos-plugin';'''

	def entryPackageJson() '''
		{
		  "name": "entry",
		  "version": "1.0.0",
		  "ohos": {
		    "org": "huawei",
		    "buildTool": "hvigor",
		    "directoryLevel": "module"
		  },
		  "description": "example description",
		  "repository": {},
		  "license": "ISC",
		  "dependencies": {}
		}
	'''

	def buildProfileJson5() '''
		{
		  "app": {
		    "signingConfigs": [],
		    "compileSdkVersion": 8,
		    "compatibleSdkVersion": 8,
		    "products": [
		      {
		        "name": "default",
		        "signingConfig": "default",
		      }
		    ]
		  },
		  "modules": [
		    {
		      "name": "entry",
		      "srcPath": "./entry",
		      "targets": [
		        {
		          "name": "default",
		          "applyToProducts": [
		            "default"
		          ]
		        }
		      ]
		    }
		  ]
		}
	'''

	def hvigorfileTs() '''export { legacyAppTasks } from '@ohos/hvigor-ohos-plugin';'''

	def packageJson() '''
		{
		  "name": "myapplication",
		  "version": "1.0.0",
		  "ohos": {
		    "org": "huawei",
		    "buildTool": "hvigor",
		    "directoryLevel": "project"
		  },
		  "description": "example description",
		  "repository": {},
		  "license": "ISC",
		  "dependencies": {
		    "@ohos/hypium": "1.0.5",
		    "@ohos/hvigor": "2.4.2",
		    "@ohos/hvigor-ohos-plugin": "2.4.2"
		  }
		}
	'''
}
