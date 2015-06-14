# Place all the behaviors and hooks related to the matching controller here.
# All this logic will automatically be available in application.js.
# You can use CoffeeScript in this file: http://coffeescript.org/

$ ->
  $( 'select#property' ).change ->
    $( 'a[data-property]' ).data( 'property', $('select#property :selected').text() )
  $( 'a[data-property]' ).click ->
    property = $( @ ).data( 'property' )
    if !!$( 'input#individual_' + property ).length
      alert 'A propriedade "' + property + '" já está presente no formulário.'

    else if property == $( 'select#property :first').text() or property == null
      alert 'Nenhuma propriedade foi selecionada.'
    
    else
      $.ajax {
        type: 'PUT',
        url: '/add_property',
        dataType: 'script',
        data: { property: property }
      }
