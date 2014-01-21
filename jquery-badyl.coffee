###
@name jquery-badyl
@description Meet Badyl – bootstrap affix-like wheel reinvent.
@version 1.7.42
@author Se7enSky studio <info@se7ensky.com>
###

###! jquery-badyl 1.7.42 http://github.com/Se7enSky/jquery-badyl###

plugin = ($) ->

	"use strict"

	class Badyl
		defaults:
			offset: 0

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
			console.log "CREATE NEW"
			@$el = $ @el
			@$el.data "badyl", @
			@config = $.extend {}, @defaults, config
			@state = null
			@badylized = no
			@$refEl = $(@$el.attr "data-badyl-ref-el")
			@prevWindowScrollTop = 0
			@badylize()

			(window.badyls or= []).push @

		destroy: ->
			@debadylize()

		badylize: ->
			return if @badylized
			@originalWidth = @$el.width()
			@originalHeight = @$el.height()

			@badylInnerHeight = @originalHeight + @config.offset * 2

			windowHeight = $(window).height()
			return if @originalHeight is 0

			@badylHeight = @$refEl.height() + @config.offset * 2

			@$el.replaceWith @$badylContainer = $("""<div>""")
				.css
					position: 'relative'
					height: "#{@badylHeight}px"
					margin: "-#{@config.offset}px 0"
				.append @$badylInner = $("""<div>""")
					.css
						width: "#{@originalWidth}px"
						height: "#{@badylInnerHeight}px"
						padding: "#{@config.offset}px 0"
					.append @$originalElement = @$el.clone()

			@$originalElement.data "badyl", @
			@$badylContainer.data "badyl", @

			@badylOffsetTop = @$badylContainer.offset().top

			@refreshInnerCss()
			@bindEvents()
			
			@badylized = yes

		rebadylize: ->
			@rebadylizeFromState = @state
			@debadylize()
			@badylize()

		debadylize: ->
			return unless @badylized
			@unbindEvents()
			@$badylContainer.replaceWith @$el = @$originalElement
			@$el.data "badyl", @
			@badylized = no
			@state = null

		bindEvents: ->
			$(window).on "scroll", @windowScrollHandler = (e) =>
				@refreshInnerCss()
			
			smartResizeTimeout = null
			$(window).on "resize", @windowResizeHandler = (e) =>
				clearTimeout smartResizeTimeout if smartResizeTimeout
				smartResizeTimeout = setTimeout =>
					@rebadylize()
					smartResizeTimeout = null
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
