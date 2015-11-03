###
@name jquery-badyl
@description Meet Badyl – bootstrap affix-like wheel reinvent.
@version 1.8.0
@author Se7enSky studio <info@se7ensky.com>
###

###! jquery-badyl 1.8.0 http://github.com/Se7enSky/jquery-badyl###

plugin = ($) ->

	"use strict"

	class Badyl
		defaults:
			offsetTop: 0
			offsetBottom: 0

		cssSnippets:
			top:
				position: 'absolute', top: 0, bottom: ''
			bottom:
				position: 'absolute', top: '', bottom: 0
			fixTop:
				position: 'fixed', top: 0, bottom: ''
			fixBottom:
				position: 'fixed', top: '', bottom: 0
			unstable:
				position: 'absolute', top: '', bottom: ''

		constructor: (@el, config) ->
			@$el = $ @el
			@$el.data "badyl", @
			if config.offset
				config.offsetTop = config.offset if typeof config.offsetTop is 'undefined'
				config.offsetBottom = config.offset if typeof config.offsetBottom is 'undefined'
			@config = $.extend {}, @defaults, config
			@state = null
			@badylized = no
			@$refEl = $(@$el.attr "data-badyl-ref-el")
			@$originalParent = @$el.parent()
			@prevWindowScrollTop = 0
			@smartResizeTimeout = null
			@badylize()

			# (window.badyls or= []).push @

		destroy: ->
			@debadylize()

		badylize: ->
			return if @badylized
			@$originalElement = @$el
			@containerInnerWidth = @measureInnerWidth @$originalParent
			@originalHeight = @$el.height()

			@badylInnerHeight = @originalHeight + @config.offsetTop + @config.offsetBottom

			# return if @originalHeight is 0

			@$refEl.css height: ""
			@badylHeight = @$refEl.height() + @config.offsetTop + @config.offsetBottom
			if @badylInnerHeight > @badylHeight
				@$refEl.css height: "#{@badylInnerHeight}px"
				@badylHeight = @$refEl.height() + @config.offsetTop + @config.offsetBottom

			@$el.wrap $("""<div class="badyl__container">""")
				.css
					position: 'relative'
					height: "#{@badylHeight}px"
					margin: "-#{@config.offsetTop}px 0 -#{@config.offsetBottom}px"
			@$el.wrap $("""<div class="badyl__inner">""")
				.css
					width: "#{@containerInnerWidth}px"
					height: "#{@badylInnerHeight}px"
					padding: "#{@config.offsetTop}px 0 #{@config.offsetBottom}px"

			@$badylContainer = @$originalParent.find ".badyl__container"
			@$badylInner = @$originalParent.find ".badyl__inner"

			@$originalElement.data "badyl", @
			@$badylContainer.data "badyl", @

			@badylOffsetTop = @$badylContainer.offset().top

			@refreshInnerCss()
			@bindEvents()
			
			@badylized = yes

			@$originalElement.trigger "badylized"

		rebadylize: ->
			return unless @badylized
			clearTimeout @smartResizeTimeout if @smartResizeTimeout

			@containerInnerWidth = @measureInnerWidth @$originalParent
			# return if @originalHeight is 0
			@rebadylizeFromState = @state
			@badylized = no
			@state = null

			@$refEl.css height: ""
			@badylHeight = @$refEl.height() + @config.offsetTop + @config.offsetBottom

			@$badylInner.css
				width: "#{@containerInnerWidth}px"
				padding: "#{@config.offsetTop}px 0 #{@config.offsetBottom}px"
			@originalHeight = @$originalElement.height()
			@badylInnerHeight = @originalHeight + @config.offsetTop + @config.offsetBottom

			if @badylInnerHeight > @badylHeight
				@$refEl.css height: "#{@badylInnerHeight}px"
				@badylHeight = @$refEl.height() + @config.offsetTop + @config.offsetBottom

			@$badylContainer.css
				position: 'relative'
				height: "#{@badylHeight}px"
				margin: "-#{@config.offsetTop}px 0 -#{@config.offsetBottom}px"
			@$badylInner.css
				height: "#{@badylInnerHeight}px"

			@badylOffsetTop = @$badylContainer.offset().top
			@refreshInnerCss()
			@badylized = yes

			@$originalElement.trigger "rebadylized"

		debadylize: ->
			return unless @badylized
			clearTimeout @smartResizeTimeout if @smartResizeTimeout
			@unbindEvents()
			@$originalElement.unwrap().unwrap()
			@$el = @$originalElement
			@$el.data "badyl", @
			@badylized = no
			@state = null
			@$el.trigger "debadylized"

		bindEvents: ->
			$(window).on "scroll", @windowScrollHandler = (e) =>
				@refreshInnerCss()
			
			$(window).on "resize", @windowResizeHandler = (e) =>
				clearTimeout @smartResizeTimeout if @smartResizeTimeout
				@smartResizeTimeout = setTimeout =>
					@rebadylize() if @badylized
					@smartResizeTimeout = null
				, 100

		unbindEvents: ->
			$(window).off "scroll", @windowScrollHandler
			$(window).off "resize", @windowResizeHandler

		refreshInnerCss: ->
			windowScrollTop = $(window).scrollTop()
			windowHeight = $(window).height()
			containerHeight = @$badylContainer.height()

			scrollingBottom = windowScrollTop > @prevWindowScrollTop
			scrollingTop = not scrollingBottom

			if @badylInnerHeight > windowHeight
				switch @state
					when null
						if windowScrollTop >= @badylOffsetTop + @badylHeight - @badylInnerHeight
							@switchState "bottom"
						else if windowScrollTop < @badylOffsetTop
							@switchState "top"
						else if @rebadylizeFromState in ["fixTop", "fixBottom"]
							@switchState @rebadylizeFromState
						else if @rebadylizeFromState is "unstable"
							@switchState "unstable",
								top: "#{@unstableTop}px"
						else if windowScrollTop > @badylOffsetTop + @badylInnerHeight - windowHeight
							@switchState "fixBottom"

					when "top"
						if windowScrollTop >= @badylOffsetTop + @badylInnerHeight - windowHeight
							@switchState "fixBottom"
					when "bottom"
						if windowScrollTop < @badylOffsetTop + @badylHeight - @badylInnerHeight
							@switchState "fixTop"
					when "fixBottom"
						if windowScrollTop + windowHeight < @badylOffsetTop + @badylInnerHeight
							@switchState "top"
						else if windowScrollTop + windowHeight >= @badylOffsetTop + @badylHeight
							@switchState "bottom"
						else if scrollingTop
							@switchState "unstable",
								top: "#{@unstableTop = windowScrollTop - @badylOffsetTop - (@badylInnerHeight - windowHeight)}px"
					when "fixTop"
						if windowScrollTop < @badylOffsetTop
							@switchState "top"
						else if windowScrollTop >= @badylOffsetTop + @badylHeight - @badylInnerHeight
							@switchState "bottom"
						else if scrollingBottom
							@switchState "unstable",
								top: "#{@unstableTop = windowScrollTop - @badylOffsetTop}px"
					when "unstable"
						if windowScrollTop < @unstableTop + @badylOffsetTop
							@switchState "fixTop"
						else if windowScrollTop >= @unstableTop + @badylOffsetTop + (@badylInnerHeight - windowHeight)
							@switchState "fixBottom"
			else
				if windowScrollTop >= @badylHeight + @badylOffsetTop - @badylInnerHeight
					@switchState "bottom"
				else if windowScrollTop > @badylOffsetTop
					@switchState "fixTop"
				else
					@switchState "top"

			@prevWindowScrollTop = windowScrollTop

		switchState: (newState, addCss) ->
			return if newState is @state
			# console.log "#{@state} -> #{newState}\t|\t#{JSON.stringify addCss}"
			@$badylInner.css @cssSnippets[newState] if @cssSnippets[newState]
			@$badylInner.css addCss if addCss
			@state = newState

		measureInnerWidth: ($el) ->
			$el.append $measureDiv = $("<div>").css display: "block", width: "100%"
			result = $measureDiv.width()
			$measureDiv.remove()
			result

	$.fn.badyl = (method, args...) ->
		@each ->
			badyl = $(@).data 'badyl'
			unless badyl
				badyl = new Badyl @, if typeof method is 'object' then method else {}

			badyl[method].apply badyl, args if typeof method is 'string'

# UMD
if typeof define is 'function' and define.amd # AMD
	define(['jquery'], plugin)
else # browser globals
	plugin(jQuery)
