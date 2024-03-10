package com.rm2pt.generator.autoark

import arkuimodel.arkUIModel.StyleClass
import arkuimodel.arkUIModel.TabsStyle
import arkuimodel.arkUIModel.TextInputStyle
import arkuimodel.arkUIModel.TextStyle
import arkuimodel.arkUIModel.NavigationStyle
import arkuimodel.arkUIModel.SearchStyle
import arkuimodel.arkUIModel.SwiperStyle
import arkuimodel.arkUIModel.ListStyle
import arkuimodel.arkUIModel.ScrollStyle
import java.util.List
import arkuimodel.arkUIModel.DividerStyle
import arkuimodel.arkUIModel.ImageStyle

class StyleGenerator {
	PageInformation info
	String name
	String assign
	String width
	String height
	String border
	String backgroundColor
	String marginTop
	String marginRight
	String marginBottom
	String marginLeft
	String paddingTop
	String paddingRight
	String paddingBottom
	String paddingLeft
	String align
	String borderRadius
	String backgroundImage
	String backgroundImageSize
	String rotate
	String zIndex
	String position
	String visibility

	new(StyleClass style, PageInformation info) {
		this.info = info
		name = style.name
		assign = style.assign
		if (assign !== null && !info.hasStyle(assign)) {
			var assignClass = info.findStyle(assign)
			var assignStyle = switch assignClass {
				TextStyle: new TextStyleGenerator(assignClass, info)
				StyleClass: new StyleGenerator(assignClass, info)
				default: throw new Exception("Undefined UI Style: " + assignClass.class.name)
			}
			info.addStyle(assignStyle)
		}
		width = info.findValue(style.width)
		height = info.findValue(style.height)
		border = info.findValue(style.border)
		backgroundColor = findColor(style.backgroundColor)
		marginTop = info.findValue(style.margintop)
		marginRight = info.findValue(style.marginright)
		marginBottom = info.findValue(style.marginbottom)
		marginLeft = info.findValue(style.marginleft)
		paddingTop = info.findValue(style.paddingtop)
		paddingRight = info.findValue(style.paddingright)
		paddingBottom = info.findValue(style.paddingbottom)
		paddingLeft = info.findValue(style.paddingleft)
		align = style.align
		borderRadius = info.findValue(style.borderRadius)
		backgroundImage = info.findValue(style.backgroundImage)
		backgroundImageSize = multiValueForm(style.backgroundImageSize, #['Auto', 'Cover', 'Contain'], "ImageSize.")
		rotate = info.findValue(style.rotate)
		zIndex = info.findValue(style.ZIndex)
		position = info.findValue(style.position)
		visibility = info.findValue(style.visibility)
	}

	def multiValueForm(String value, List<String> options, String prefix) {
		return value !== null && options.contains(value)
			? '''«prefix»«value»''' : info.findValue(value)
	}

	def getName() { return name }

	def styleCode() '''
		«IF assign !== null».«assign»()«ENDIF»
		«IF width !== null».width(«width»)«ENDIF»
		«IF height !== null».height(«height»)«ENDIF»
		«IF border !== null».borderRadius(«border»)«ENDIF»
		«IF backgroundColor !== null».backgroundColor(«backgroundColor»)«ENDIF»
		«IF marginTop !== null || marginRight !== null || marginBottom !== null || marginLeft !== null»
			.margin({
				«IF marginTop !== null»top: «marginTop»,«ENDIF»
				«IF marginRight !== null»right: «marginRight»,«ENDIF»
				«IF marginBottom !== null»bottom: «marginBottom»,«ENDIF»
				«IF marginLeft !== null»left: «marginLeft»,«ENDIF»
			})
		«ENDIF»
		«IF paddingTop !== null || paddingRight !== null || paddingBottom !== null || paddingLeft !== null»
			.padding({
				«IF paddingTop !== null»top: «paddingTop»,«ENDIF»
				«IF paddingRight !== null»right: «paddingRight»,«ENDIF»
				«IF paddingBottom !== null»bottom: «paddingBottom»,«ENDIF»
				«IF paddingLeft !== null»left: «paddingLeft»,«ENDIF»
			})
		«ENDIF»
		«IF align !== null».align(Alignment.«align»)«ENDIF»
		«IF borderRadius !== null».borderRadius(«borderRadius»)«ENDIF»
		«IF backgroundImage !== null».backgroundImage(«backgroundImage»)«ENDIF»
		«IF backgroundImageSize !== null».backgroundImageSize(«backgroundImageSize»)«ENDIF»
		«IF rotate !== null».rotate(«rotate»)«ENDIF»
		«IF zIndex !== null».zIndex(«zIndex»)«ENDIF»
		«IF position !== null».position(«position»)«ENDIF»
		«IF visibility !== null».visibility(«visibility»)«ENDIF»
		«componentStyle»
	'''

	def componentName() ''''''

	def componentStyle() ''''''

	def stylePrefix() {
		if (componentName !== null && componentName.length > 0)
			'''
				@Extend(«componentName»)
			'''
		else
			'''
				@Styles
			'''
	}

	def findColor(String color) {
		return color !== null && Character.isUpperCase(color.charAt(0)) ? "Color." + color : info.findValue(color)
	}
}

class TabsStyleGenerator extends StyleGenerator {
	String barHeight
	String barMode

	new(StyleClass style, PageInformation info) {
		super(style, info)
		var tabs = style as TabsStyle
		barHeight = info.findValue(tabs.barHeight)
		barMode = tabs.barMode
	}

	override componentStyle() '''
		«IF barHeight !== null».barHeight(«barHeight»)«ENDIF»
		«IF barMode !== null».barMode(BarMode.«barMode»)«ENDIF»
	'''
}

class TextStyleGenerator extends StyleGenerator {
	String color
	String size
	String style
	String weight
	String textAlign

	new(StyleClass style, PageInformation info) {
		super(style, info)
		var text = style as TextStyle
		color = findColor(text.fontColor)
		size = info.findValue(text.fontSize)
		style = text.fontStyle
		weight = multiValueForm(text.fontWeight, #['Lighter', 'Normal', 'Regular', 'Medium', 'Bold', 'Bolder'],
			"FontWeight.")
		textAlign = text.textAlign
	}

	override componentName() '''Text'''

	override componentStyle() '''
		«IF color !== null».fontColor(«color»)«ENDIF»
		«IF size !== null».fontSize(«size»)«ENDIF»
		«IF style !== null».fontStyle(FontStyle.«style»)«ENDIF»
		«IF weight !== null».fontWeight(«weight»)«ENDIF»
		«IF textAlign !== null».textAlign(TextAlign.«textAlign»)«ENDIF»
	'''
}

class TextInputStyleGenerator extends StyleGenerator {
	String type
	String length
	String color

	new(StyleClass style, PageInformation info) {
		super(style, info)
		var input = style as TextInputStyle
		type = input.type
		length = info.findValue(input.maxLength)
		color = findColor(input.fontColor)
	}

	override componentStyle() '''
		«IF type !== null».type(InputType.«type»)«ENDIF»
		«IF length !== null».maxLength(«length»)«ENDIF»
		«IF color !== null».fontColor(«color»)«ENDIF»
	'''
}

class NavigationStyleGenerator extends StyleGenerator {
	Boolean hideBackButton
	Boolean hideToolBar
	String title
	String titleMode

	new(StyleClass style, PageInformation info) {
		super(style, info)
		var navi = style as NavigationStyle
		hideBackButton = navi.hideBackButton
		hideToolBar = navi.hideToolBar
		title = info.findValue(navi.title)
		titleMode = navi.titleMode
	}

	override componentStyle() '''
		«IF hideBackButton !== null».hideBackButton(«hideBackButton»)«ENDIF»
		«IF hideToolBar !== null».hideToolBar(«hideToolBar»)«ENDIF»
		«IF title !== null».title(«title»)«ENDIF»
		«IF titleMode !== null».titleMode(NavigationTitleMode.«titleMode»)«ENDIF»
	'''
}

class SearchStyleGenerator extends StyleGenerator {
	String placeholderSize
	String placeholderWeight

	new(StyleClass style, PageInformation info) {
		super(style, info)
		var search = style as SearchStyle
		placeholderSize = info.findValue(search.placeholderSize)
		placeholderWeight = info.findValue(search.placeholderWeight)
	}

	override componentStyle() '''
		«IF placeholderSize !== null || placeholderWeight !== null»
			.placeholderFont({
				«IF placeholderSize !== null»size: «placeholderSize»,«ENDIF»
				«IF placeholderWeight !== null»weight: «placeholderWeight»,«ENDIF»
			})
		«ENDIF»
	'''
}

class SwiperStyleGenerator extends StyleGenerator {
	String autoPlay

	new(StyleClass style, PageInformation info) {
		super(style, info)
		var swiper = style as SwiperStyle
		autoPlay = swiper.autoPlay
	}

	override componentStyle() '''
		«IF autoPlay !== null».autoPlay(«autoPlay»)«ENDIF»
	'''
}

class ListStyleGenerator extends StyleGenerator {
	String divider

	new(StyleClass style, PageInformation info) {
		super(style, info)
		var list = style as ListStyle
		divider = info.findValue(list.divider)
	}

	override componentStyle() '''
		«IF divider !== null».divider(«divider»)«ENDIF»
	'''
}

class ScrollStyleGenerator extends StyleGenerator {
	String scrollBar
	String scrollable

	new(StyleClass style, PageInformation info) {
		super(style, info)
		var scroll = style as ScrollStyle
		scrollBar = scroll.scrollBar
		scrollable = scroll.scrollable
	}

	override componentStyle() '''
		«IF scrollBar !== null».scrollBar(BarState.«scrollBar»)«ENDIF»
		«IF scrollable !== null».scrollable(ScrollDirection.«scrollable»)«ENDIF»
	'''
}

class DividerStyleGenerator extends StyleGenerator {
	String color

	new(StyleClass style, PageInformation info) {
		super(style, info)
		var divider = style as DividerStyle
		color = findColor(divider.color)
	}

	override componentStyle() '''
		«IF color !== null».color(«color»)«ENDIF»
	'''
}

class ImageStyleGenerator extends StyleGenerator {
	String objectFit

	new(StyleClass style, PageInformation info) {
		super(style, info)
		var image = style as ImageStyle
		objectFit = image.objectFit
	}

	override componentStyle() '''
		«IF objectFit !== null».objectFit(ImageFit.«objectFit»)«ENDIF»
	'''
}
