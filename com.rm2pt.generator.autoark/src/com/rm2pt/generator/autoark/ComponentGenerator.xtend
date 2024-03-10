package com.rm2pt.generator.autoark

import arkuimodel.arkUIModel.ButtonWidget
import arkuimodel.arkUIModel.ColumnContainer
import arkuimodel.arkUIModel.Container
import arkuimodel.arkUIModel.ContainerItems
import arkuimodel.arkUIModel.GridContainer
import arkuimodel.arkUIModel.GridItemContainer
import arkuimodel.arkUIModel.ImageWidget
import arkuimodel.arkUIModel.ListContainer
import arkuimodel.arkUIModel.ListItemContainer
import arkuimodel.arkUIModel.NavigationContainer
import arkuimodel.arkUIModel.PageRefrence
import arkuimodel.arkUIModel.RowContainer
import arkuimodel.arkUIModel.ScrollContainer
import arkuimodel.arkUIModel.TabContent
import arkuimodel.arkUIModel.TabItem
import arkuimodel.arkUIModel.TabsContainer
import arkuimodel.arkUIModel.TextInputWidget
import arkuimodel.arkUIModel.TextWidget
import arkuimodel.arkUIModel.UIComponent
import arkuimodel.arkUIModel.FlexContainer
import arkuimodel.arkUIModel.ToggleWidget
import arkuimodel.arkUIModel.SearchWidget
import arkuimodel.arkUIModel.SwiperWidget
import arkuimodel.arkUIModel.BlankWidget
import arkuimodel.arkUIModel.StackContainer
import arkuimodel.arkUIModel.DividerWidget
import arkuimodel.arkUIModel.CustomDialogContainer

abstract class ComponentGenerator {
	UIComponent component
	PageInformation info

	new(UIComponent component, PageInformation info) {
		this.component = component
		this.info = info
	}

	def getInfo() { return info }

	def generateIf() {
		if (component.getIf !== null) {
			var exp = info.findValue(component.getIf.autoExpression)
			return '''
				if («exp») {
					«generateForEach»
				}
			'''
		} else {
			return generateForEach
		}
	}

	def generateForEach() {
		if (component.foreach !== null) {
			var arr = info.findValue('''${«component.foreach.array»}''')
			var type = component.foreach.arrayType
			var item = component.foreach.item
			var variable = new ArkUIVariable(item, type, '''${«item»}''', VariableDeclaration.LOCAL)
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

	def String componentName()

	def componentParameters() ''''''

	def CharSequence componentAttributes()

	def CharSequence componentEvents()

	def componentBuilders() ''''''

	def String componentCode() {
		if (component instanceof Container)
			'''
				«componentName»(«componentParameters») {
					«FOR sub : component.widget»
						«generateComponent(sub, info)»
					«ENDFOR»
					«FOR ref : component.pagerefrence»
						«findReference(ref, info, false)»
					«ENDFOR»
				}
				«componentAttributes»
				«componentEvents»
				«componentBuilders»
			'''
		else
			'''
				«componentName»(«componentParameters»)
					«componentAttributes»
					«componentEvents»
					«componentBuilders»
			'''
	}

	def static findComponent(UIComponent component, PageInformation info) {
		return switch component {
			TabsContainer: new TabsGenerator(component, info)
			TabContent: new TabGenerator(component, info)
			ScrollContainer: new ScrollGenerator(component, info)
			SwiperWidget: new SwiperGenerator(component, info)
			ColumnContainer: new ColumnGenerator(component, info)
			RowContainer: new RowGenerator(component, info)
			FlexContainer: new FlexGenerator(component, info)
			GridContainer: new GridGenerator(component, info)
			GridItemContainer: new GridItemGenerator(component, info)
			NavigationContainer: new NavigationGenerator(component, info)
			ListContainer: new ListGenerator(component, info)
			ListItemContainer: new ListItemGenerator(component, info)
			StackContainer: new StackGenerator(component, info)
			TextWidget: new TextGenerator(component, info)
			ImageWidget: new ImageGenerator(component, info)
			TextInputWidget: new TextInputGenerator(component, info)
			ButtonWidget: new ButtonGenerator(component, info)
			ToggleWidget: new ToggleGenerator(component, info)
			SearchWidget: new SearchGenerator(component, info)
			BlankWidget: new BlankGenerator(component, info)
			DividerWidget: new DividerGenerator(component, info)
			CustomDialogContainer: new CustomDialogGenerator(component, info)
			TabItem,
			ContainerItems: null
			default: throw new Exception("Undefined UI Component: " + component.class.name)
		}
	}

	def static generateComponent(UIComponent component, PageInformation info) {
		var generator = findComponent(component, info)
		return generator !== null ? generator.generateIf : ''''''
	}

	def findBuilder(UIComponent component) {
		var builder = new BuilderGenerator(component, info)
		if (!info.root.hasBuilder(builder.builderName)) {
			info.root.addBuilder(builder)
		}
		return builder.referenceCode
	}

	def static findReference(PageRefrence ref, PageInformation info, Boolean isDialog) {
		for (page : info.pages) {
			if (page.pageTitle == ref.name) {
				page.generatePage(isDialog)
				info.addImport(ref.name, '''"./«ref.name»"''')
				return page.ifReference(ref, info)
			}
		}
	}

	def findContainerItems(String name) {
		for (uiComponent : component.widget) {
			if (uiComponent instanceof ContainerItems && uiComponent.name == name) {
				return uiComponent
			}
		}
	}
}

class TabsGenerator extends ComponentGenerator {
	TabsContainer tabs
	ArkUIVariable controller
	String barPosition

	new(UIComponent component, PageInformation info) {
		super(component, info)
		tabs = component as TabsContainer
		controller = new ArkUIVariable(tabs.id + "Controller", "TabsController", "new TabsController()",
			VariableDeclaration.PRIVATE)
		info.addVariable(controller)
		barPosition = tabs.barPosition
	}

	override componentName() '''Tabs'''

	override componentParameters() '''{ controller: this.«controller.name»«IF barPosition !== null», barPosition: BarPosition.«barPosition»«ENDIF» }'''

	override componentAttributes() { return new TabsStyleGenerator(tabs.tabsstyle, info).styleCode }

	override componentEvents() { return new EventGenerator(tabs.tabsevent, info).eventCode }
}

class TabGenerator extends ComponentGenerator {
	TabContent tab
	TabItem tabItem

	new(UIComponent component, PageInformation info) {
		super(component, info)
		tab = component as TabContent
		tabItem = findTabItem
	}

	def findTabItem() {
		for (uiComponent : tab.widget) {
			if (uiComponent instanceof TabItem) {
				return uiComponent
			}
		}
	}

	override componentName() '''TabContent'''

	override componentAttributes() { return new StyleGenerator(tab.tabcontentstyle, info).styleCode }

	override componentEvents() ''''''

	override componentBuilders() '''
		«IF tabItem !== null»
			.tabBar(«findBuilder(tabItem)»)
		«ENDIF»
	'''
}

class ScrollGenerator extends ComponentGenerator {
	ScrollContainer scroll

	new(UIComponent component, PageInformation info) {
		super(component, info)
		scroll = component as ScrollContainer
	}

	override componentName() '''Scroll'''

	override componentAttributes() { return new ScrollStyleGenerator(scroll.scrollstyle, info).styleCode }

	override componentEvents() { return new EventGenerator(scroll.scrollevent, info).eventCode }
}

class SwiperGenerator extends ComponentGenerator {
	SwiperWidget swiper
	ArkUIVariable controller

	new(UIComponent component, PageInformation info) {
		super(component, info)
		swiper = component as SwiperWidget
		controller = new ArkUIVariable(swiper.id + "Controller", "SwiperController", "new SwiperController()",
			VariableDeclaration.PRIVATE)
		info.addVariable(controller)
	}

	override componentName() '''Swiper'''

	override componentParameters() '''this.«controller.name»'''

	override componentAttributes() { return new StyleGenerator(swiper.swiperstyle, info).styleCode }

	override componentEvents() { return new EventGenerator(swiper.swiperevent, info).eventCode }
}

class ColumnGenerator extends ComponentGenerator {
	ColumnContainer column
	String space
	String justifyContent
	String alignItems

	new(UIComponent component, PageInformation info) {
		super(component, info)
		column = component as ColumnContainer
		space = info.findValue(column.space)
		justifyContent = column.justifyContent
		alignItems = column.alignItems
	}

	override componentName() '''Column'''

	override componentParameters() '''«IF space !== null && space !== ''»{ space: «space» }«ENDIF»'''

	override componentAttributes() '''
		«new StyleGenerator(column.columnstyle, info).styleCode»
		«IF justifyContent !== null».justifyContent(FlexAlign.«justifyContent»)«ENDIF»
		«IF alignItems !== null».alignItems(HorizontalAlign.«alignItems»)«ENDIF»
	'''

	override componentEvents() { return new EventGenerator(column.columnevent, info).eventCode }
}

class RowGenerator extends ComponentGenerator {
	RowContainer row
	String space
	String justifyContent
	UIComponent menu

	new(UIComponent component, PageInformation info) {
		super(component, info)
		row = component as RowContainer
		space = info.findValue(row.space)
		justifyContent = row.justifyContent
		menu = findContainerItems("menu")
	}

	override componentName() '''Row'''

	override componentParameters() '''«IF space !== null && space !== ''»{ space: «space» }«ENDIF»'''

	override componentAttributes() '''
		«new StyleGenerator(row.rowstyle, info).styleCode»
		«IF justifyContent !== null».justifyContent(FlexAlign.«justifyContent»)«ENDIF»
	'''

	override componentEvents() { return new EventGenerator(row.rowevent, info).eventCode }

	override componentBuilders() '''
		«IF menu !== null»
			.bindMenu(«findBuilder(menu)»)
		«ENDIF»
	'''
}

class FlexGenerator extends ComponentGenerator {
	FlexContainer flex
	String direction
	String justifyContent
	String alignItems

	new(UIComponent component, PageInformation info) {
		super(component, info)
		flex = component as FlexContainer
		direction = flex.direction
		justifyContent = flex.justifyContent
		alignItems = flex.alignItems
	}

	override componentName() '''Flex'''

	override componentParameters() '''{
		«IF direction !== null»direction: FlexDirection.«direction»,«ENDIF»
		«IF justifyContent !== null»justifyContent: FlexAlign.«justifyContent»,«ENDIF»
		«IF alignItems !== null»alignItems: ItemAlign.«alignItems»,«ENDIF»
	}'''

	override componentAttributes() { return new StyleGenerator(flex.flexstyle, info).styleCode }

	override componentEvents() { return new EventGenerator(flex.flexevent, info).eventCode }
}

class GridGenerator extends ComponentGenerator {
	GridContainer grid
	String columnsTemplate
	String rowsTemplate
	String columnsGap
	String rowsGap

	new(UIComponent component, PageInformation info) {
		super(component, info)
		grid = component as GridContainer
		columnsTemplate = info.findValue(grid.columnsTemplate)
		rowsTemplate = info.findValue(grid.rowsTemplate)
		columnsGap = info.findValue(grid.columnsGap)
		rowsGap = info.findValue(grid.rowsGap)
	}

	override componentName() '''Grid'''

	override componentAttributes() '''
		«new StyleGenerator(grid.gridstyle, info).styleCode»
		«IF columnsTemplate !== null».columnsTemplate(«columnsTemplate»)«ENDIF»
		«IF rowsTemplate !== null».rowsTemplate(«rowsTemplate»)«ENDIF»
		«IF columnsGap !== null».columnsGap(«columnsGap»)«ENDIF»
		«IF rowsGap !== null».rowsGap(«rowsGap»)«ENDIF»
	'''

	override componentEvents() { return new EventGenerator(grid.gridevent, info).eventCode }
}

class GridItemGenerator extends ComponentGenerator {
	GridItemContainer gridItem

	new(UIComponent component, PageInformation info) {
		super(component, info)
		gridItem = component as GridItemContainer
	}

	override componentName() '''GridItem'''

	override componentAttributes() { return new StyleGenerator(gridItem.griditemstyle, info).styleCode }

	override componentEvents() { return new EventGenerator(gridItem.griditemevent, info).eventCode }
}

class NavigationGenerator extends ComponentGenerator {
	NavigationContainer nav
	UIComponent title
	UIComponent menus

	new(UIComponent component, PageInformation info) {
		super(component, info)
		nav = component as NavigationContainer
		title = findContainerItems("title")
		menus = findContainerItems("menu")
	}

	override componentName() '''Navigation'''

	override componentAttributes() { return new NavigationStyleGenerator(nav.navigationstyle, info).styleCode }

	override componentEvents() { return new EventGenerator(nav.navigationevent, info).eventCode }

	override componentBuilders() '''
		«IF title !== null»
			.title(«findBuilder(title)»)
		«ENDIF»
		«IF menus !== null»
			.menus(«findBuilder(menus)»)
		«ENDIF»
	'''
}

class ListGenerator extends ComponentGenerator {
	ListContainer list
	String space

	new(UIComponent component, PageInformation info) {
		super(component, info)
		list = component as ListContainer
		space = info.findValue(list.space)
	}

	override componentName() '''List'''

	override componentParameters() '''«IF space !== null»{ space: «space» }«ENDIF»'''

	override componentAttributes() { return new ListStyleGenerator(list.liststyle, info).styleCode }

	override componentEvents() { return new EventGenerator(list.listevent, info).eventCode }
}

class ListItemGenerator extends ComponentGenerator {
	ListItemContainer listItem

	new(UIComponent component, PageInformation info) {
		super(component, info)
		listItem = component as ListItemContainer
	}

	override componentName() '''ListItem'''

	override componentAttributes() { return new StyleGenerator(listItem.listitemstyle, info).styleCode }

	override componentEvents() { return new EventGenerator(listItem.listitemevent, info).eventCode }
}

class StackGenerator extends ComponentGenerator {
	StackContainer stack

	new(UIComponent component, PageInformation info) {
		super(component, info)
		stack = component as StackContainer
	}

	override componentName() '''Stack'''

	override componentAttributes() { return new StyleGenerator(stack.stackstyle, info).styleCode }

	override componentEvents() { return new EventGenerator(stack.stackevent, info).eventCode }
}

class TextGenerator extends ComponentGenerator {
	TextWidget text
	String content

	new(UIComponent component, PageInformation info) {
		super(component, info)
		text = component as TextWidget
		content = info.findValue(text.content)
	}

	override componentName() '''Text'''

	override componentParameters() '''«IF content !== null»«content»«ENDIF»'''

	override componentAttributes() { return new TextStyleGenerator(text.textstyle, info).styleCode }

	override componentEvents() { return new EventGenerator(text.textevent, info).eventCode }
}

class ImageGenerator extends ComponentGenerator {
	ImageWidget image
	String src

	new(UIComponent component, PageInformation info) {
		super(component, info)
		image = component as ImageWidget
		src = if (image.src.contains("${"))
			info.findValue(image.src)
		else if (image.src.contains("://"))
			'''"«image.src»"'''
		else if (image.src.contains("$r"))
			'''«image.src»'''
		else
			'''$r("app.media.«image.src»")'''
	}

	override componentName() '''Image'''

	override componentParameters() '''«IF src !== null»«src»«ENDIF»'''

	override componentAttributes() { return new ImageStyleGenerator(image.imagestyle, info).styleCode }

	override componentEvents() { return new EventGenerator(image.imageevent, info).eventCode }
}

class TextInputGenerator extends ComponentGenerator {
	TextInputWidget input
	String text
	String placeholder

	new(UIComponent component, PageInformation info) {
		super(component, info)
		input = component as TextInputWidget
		text = info.findValue(input.text)
		placeholder = info.findValue(input.placeholder)
	}

	override componentName() '''TextInput'''

	override componentParameters() '''{ «IF text !== null»text: «text», «ENDIF»«IF placeholder !== null»placeholder: «placeholder», «ENDIF» }'''

	override componentAttributes() { return new TextInputStyleGenerator(input.textinputstyle, info).styleCode }

	override componentEvents() { return new TextInputEventGenerator(input, info).eventCode }
}

class ButtonGenerator extends ComponentGenerator {
	ButtonWidget button
	String label
	String type
	String stateEffect

	new(UIComponent component, PageInformation info) {
		super(component, info)
		button = component as ButtonWidget
		label = info.findValue(button.label)
		type = button.type
		stateEffect = button.stateEffect
	}

	override componentName() '''Button'''

	override componentParameters() '''«IF label !== null»«label», «ENDIF»{ «IF type !== null»type: ButtonType.«type», «ENDIF»«IF stateEffect !== null»stateEffect: «stateEffect», «ENDIF» }'''

	override componentAttributes() { return new StyleGenerator(button.buttonstyle, info).styleCode }

	override componentEvents() { return new EventGenerator(button.buttonevent, info).eventCode }
}

class ToggleGenerator extends ComponentGenerator {
	ToggleWidget toggle
	String type
	String isOn

	new(UIComponent component, PageInformation info) {
		super(component, info)
		toggle = component as ToggleWidget
		type = toggle.toggleType
		isOn = info.findValue(toggle.isOn)
	}

	override componentName() '''Toggle'''

	override componentParameters() '''{ «IF type !== null»type: ToggleType.«type», «ENDIF»«IF isOn !== null»isOn: «isOn», «ENDIF» }'''

	override componentAttributes() { return new StyleGenerator(toggle.togglestyle, info).styleCode }

	override componentEvents() { return new EventGenerator(toggle.toggleevent, info).eventCode }
}

class SearchGenerator extends ComponentGenerator {
	SearchWidget search
	ArkUIVariable controller
	String value
	String placeholder
	String searchButton

	new(UIComponent component, PageInformation info) {
		super(component, info)
		search = component as SearchWidget
		controller = new ArkUIVariable(search.id + "Controller", "SearchController", "new SearchController()",
			VariableDeclaration.PRIVATE)
		info.addVariable(controller)
		value = info.findValue(search.value)
		placeholder = info.findValue(search.placeholder)
		searchButton = info.findValue(search.searchbutton)
	}

	override componentName() '''Search'''

	override componentParameters() '''
		{
			«IF value !== null»value: «value»,«ENDIF»
			«IF placeholder !== null»placeholder: «placeholder»,«ENDIF»
			controller: this.«controller.name»,
		}
	'''

	override componentAttributes() '''
		«new SearchStyleGenerator(search.searchstyle, info).styleCode»
		«IF searchButton !== null».searchButton(«searchButton»)«ENDIF»
	'''

	override componentEvents() { return new EventGenerator(search.searchevent, info).eventCode }
}

class BlankGenerator extends ComponentGenerator {
	BlankWidget blank

	new(UIComponent component, PageInformation info) {
		super(component, info)
		blank = component as BlankWidget
	}

	override componentName() '''Blank'''

	override componentAttributes() { return new StyleGenerator(blank.blankstyle, info).styleCode }

	override componentEvents() ''''''
}

class DividerGenerator extends ComponentGenerator {
	DividerWidget divider

	new(UIComponent component, PageInformation info) {
		super(component, info)
		divider = component as DividerWidget
	}

	override componentName() '''Divider'''

	override componentAttributes() { return new DividerStyleGenerator(divider.dividerstyle, info).styleCode }

	override componentEvents() ''''''
}

class CustomDialogGenerator extends ComponentGenerator {
	CustomDialogContainer dialog
	ArkUIVariable controller

	new(UIComponent component, PageInformation info) {
		super(component, info)
		dialog = component as CustomDialogContainer
		if (component.pagerefrence.size != 1) {
			throw new Exception("CustomDialog should only contain ONE builder!")
		}
		var ref = component.pagerefrence.get(0)
		controller = new ArkUIVariable(dialog.id + "Controller", "CustomDialogController", '''
			new CustomDialogController({
				builder: «findReference(ref, info, true)»,
				autoCancel: true,
				customStyle: true
			})
		''', VariableDeclaration.PRIVATE)
		info.addVariable(controller)
	}

	override componentName() ''''''

	override componentAttributes() ''''''

	override componentEvents() ''''''

	override componentCode() ''''''
}
