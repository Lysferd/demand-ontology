# Place all the behaviors and hooks related to the matching controller here.
# All this logic will automatically be available in application.js.
# You can use CoffeeScript in this file: http://coffeescript.org/

$ ->
  $( 'select#property' ).change ->
    $( 'a[data-label]' ).data 'label', $('select#property :selected').text()
    $( 'a[data-property]' ).data 'property', $( 'select#property :selected' ).val()

  $( 'a[data-property]' ).click ->
    label = $( @ ).data( 'label' )
    property = $( @ ).data( 'property' )

    if !!$( 'input#individual_' + property ).length
      alert 'A propriedade "' + label + '" já está presente no formulário.'

    else if property == $( 'select#property :first').text() or property == null
      alert 'Nenhuma propriedade foi selecionada.'
    
    else
      $.ajax {
        type: 'PUT',
        url: '/add_property',
        dataType: 'script',
        data: { label: label, property: property }
      }
