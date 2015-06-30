# Place all the behaviors and hooks related to the matching controller here.
# All this logic will automatically be available in application.js.
# You can use CoffeeScript in this file: http://coffeescript.org/

$ ->
  # -=-=-=-=-
  # AJAX Callbacks.
  $( document ).on 'ajax:before ajaxStart page:fetch', ->
    $( 'div#spinner' ).fadeIn 'fast'
  $( document ).on 'ajax:complete ajaxComplete page:change', ( event, xhr ) ->
    $( 'div#spinner' ).fadeOut 'fast'