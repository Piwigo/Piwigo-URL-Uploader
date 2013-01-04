/**
 * jQuery textareaLinesNumbers 2.0
 *
 * Copyright 2012, Damien "Mistic" Sorel
 *    http://www.strangeplanet.fr
 *
 * Dual licensed under the MIT or GPL Version 3 licenses.
 *    http://www.opensource.org/licenses/mit-license.php
 *    http://www.gnu.org/licenses/gpl.html
 *
 * Depends:
 *	  jquery.js
 *    jquery-ui.js | resizable (optional)
 */
  

(function($) {
    /**
     * Plugin declaration
     */
    $.fn.textareaLinesNumbers = function(options) {
        // callable public methods
        var callable = [];
        
        var plugin = $(this).data('textareaLinesNumbers');
        
        // already instantiated and trying to execute a method
        if (plugin && typeof options === 'string') {
            if ($.inArray(options,callable)!==false) {
                return plugin[options].apply(plugin, Array.prototype.slice.call(arguments, 1));
            }
            else {
                throw 'Method "' + options + '" does not exist on jQuery.textareaLinesNumbers';
            }
        }
        // not instantiated and trying to pass options object (or nothing)
        else if (!plugin && (typeof options === 'object' || !options)) {
            if (!options) {
                options = {};
            }
            
            // extend defaults
            options = $.extend({}, $.fn.textareaLinesNumbers.defaults, options);

            // for each element instantiate the plugin
            return this.each(function() {
                var plugin = $(this).data('textareaLinesNumbers');

                // create new instance of the plugin if the plugin isn't initialised
                if (!plugin) {
                    plugin = new $.textareaLinesNumbers($(this), options);
                    plugin.init();
                    $(this).data('textareaLinesNumbers', plugin);
                }
            });
        }
    }
    
    /**
     * Defaults
     */
    $.fn.textareaLinesNumbers.defaults = {
      lines: 100,
      trailing: '',
      resizable: false,
      id: null
    };

    /**
     * Main plugin function
     */
    $.textareaLinesNumbers = function(element, options) {
        this.options = options;
        
        if (element instanceof jQuery) {
            this.$textarea = element;
        }
        else {
            this.$textarea = $(element);
        }
        
        this.$main = null;
        this.$linesContainer = null;
        
        
        /*
         * init the plugin
         * scope: private
         */
        this.init = function() {
            // build the HTML wrapper
            if (this.$textarea.closest('.textareaLinesNumbers').length <= 0) {
                this.$textarea.wrap('<div class="textareaLinesNumbers" />');
            }
            this.$main = this.$textarea.parent('.textareaLinesNumbers');

            if (this.$main.find('.linesContainer').length <= 0) {
                this.$main.prepend('<textarea class="linesContainer"></textareay>');
            }
            this.$linesContainer = this.$main.children('.linesContainer');

            // set id
            if (this.options.id != null) {
                this.$main.attr('id', this.options.id);
            }
            
            // add liner
            this.setupLiner();

            // bind the events
            this.bindEvents();

            // apply the resizeable
            this.applyResizable();

            // highlight content
            this.setLine();
        }
        
        /*
         * add events handlers
         * scope: private
         */
        this.bindEvents = function() {
            var events = this.$textarea.data('textareaLinesNumbersEvents');
            
            if (typeof events != 'boolean' || events !== true) {
                // add triggers to textarea
                this.$textarea.on({
                    'input.textareaLinesNumbers' :  $.proxy(function(){ this.setLine(); }, this),
                    'scroll.textareaLinesNumbers' :  $.proxy(function(){ this.setLine(); }, this),
                    'blur.textareaLinesNumbers' :  $.proxy(function(){ this.setLine(); }, this),
                    'focus.textareaLinesNumbers' :  $.proxy(function(){ this.setLine(); }, this),
                    'resize.textareaLinesNumbers' :  $.proxy(function(){ this.updateSize(); this.setLine(); }, this)
                });

                this.$textarea.data('textareaLinesNumbersEvents', true);
            }
        }

        /*
         * set style of containers
         * scope: private
         */
        this.setupLiner = function() {
            // liner content
            var string = '1'+this.options.trailing;
            for (var no=2; no<=this.options.lines; no++) {
              string+= '\n'+no+this.options.trailing;
            }
            this.$linesContainer.html(string);
            
            // the main container has the same size and position than the original textarea
            this.cloneCss(this.$textarea, this.$main, [
                'float','vertical-align','margin-top','margin-bottom','margin-right','margin-left'
            ]);
            
            // the liner has the same font than the original textarea
            this.cloneCss(this.$textarea, this.$linesContainer, [
                'font-size','line-height','font-family','vertical-align','padding-top'
            ]);
            
            var width = (this.options.lines.toString().length+this.options.trailing.toString().length)*this.charWidth(this.$linesContainer.css('font-family'));
            
            this.$linesContainer.css({
                'padding-top': 0
                    + this.toPx(this.$textarea.css('padding-top')) 
                    + this.toPx(this.$textarea.css('border-top-width')) 
                    - this.toPx(this.$linesContainer.css('border-top-width')),
                'padding-bottom': 0
                    + this.toPx(this.$textarea.css('padding-bottom')) 
                    + this.toPx(this.$textarea.css('border-bottom-width')) 
                    - this.toPx(this.$linesContainer.css('border-bottom-width')),
                'top'  : this.$textarea.position().top,
                'left' : this.$textarea.position().left,
                'width' : width
            });
            
            this.updateSize();
            
            this.$textarea.css({
                'margin': 0,
                'margin-left': this.$linesContainer.outerWidth(),
                'width': this.$textarea.width() - width
            });
            
            this.$textarea.attr("wrap", "off");
        }
        
        /*
         * set textarea as resizable
         * scope: private
         */
        this.applyResizable = function() {
            if (this.options.resizable && jQuery.ui) {
                this.$textarea.resizable({
                    'handles': 'se',
                    'resize':  $.proxy(function() { this.updateSize(); }, this)
                });
            }
        }

        /*
         * scroll $linesConatainer according to $textarea scroll
         * scope: private
         */
        this.setLine = function() {
            this.$linesContainer.scrollTop(this.$textarea.scrollTop());
        }
        
        /*
         * update liner height
         * scope: private
         */
        this.updateSize = function() {
            this.$main.css({
                'width':  this.$textarea.outerWidth(),
                'height': this.$textarea.outerHeight()
            });
            
            this.$linesContainer.css({
                'height': this.$textarea.outerHeight() 
                    - this.toPx(this.$textarea.css('padding-top'))
                    - this.toPx(this.$textarea.css('padding-bottom'))
                    - this.toPx(this.$textarea.css('border-top-width'))
                    - this.toPx(this.$textarea.css('border-bottom-width')),
            });
        }

        /*
         * set 'to' css attributes listed in 'what' as defined for 'from'
         * scope: private
         */
        this.cloneCss = function(from, to, what) {
            for (var i=0; i<what.length; i++) {
                to.css(what[i], from.css(what[i]));
            }
        }

        /*
         * clean/convert px and em size to px size (without 'px' suffix)
         * scope: private
         */
        this.toPx = function(value) {
            if (value != value.replace('em', '')) {
                // https://github.com/filamentgroup/jQuery-Pixel-Em-Converter
                var that = parseFloat(value.replace('em', '')),
                    scopeTest = $('<div style="display:none;font-size:1em;margin:0;padding:0;height:auto;line-height:1;border:0;">&nbsp;</div>').appendTo('body'),
                    scopeVal = scopeTest.height();
                scopeTest.remove();
                return Math.round(that * scopeVal);
            }
            else if (value != value.replace('px', '')) {
                return parseInt(value.replace('px', ''));
            }
            else {
                return parseInt(value);
            }
        }
        
        /*
         * get chard width for given font (should be monospace)
         * scope: private
         */
        this.charWidth = function(font_family) {
            var scopeTest = $('<div style="display:none;font-size:1em;font-family:'+font_family+'margin:0;padding:0;border:0;">0123456789</div>').appendTo('body'),
                scopeVal = scopeTest.width();
            scopeTest.remove();
            return Math.floor(scopeVal/10);
        }
    };
})(jQuery);