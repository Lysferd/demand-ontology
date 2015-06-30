# Place all the behaviors and hooks related to the matching controller here.
# All this logic will automatically be available in application.js.
# You can use CoffeeScript in this file: http://coffeescript.org/

$ ->
  $( 'form#new_individual select#property' ).change ->
    values = $('select#property :selected').val().split ':'
    $('a[data-property]').data 'type', values[0]
    $('a[data-property]').data 'property', values[1]
    console.log values

  $( 'a[data-property]' ).click ->
    dataset_id = $(@).data 'dataset-id'
    type = $(@).data 'type'
    property = $(@).data 'property'

    console.log $(@).data()

    if !!$('label[for="individual_property_' + type + ':' + property + '"]').length
      alert 'A propriedade "' + property + '" já está presente no formulário.'
    else if property == $( 'select#property :first' ).text() or property == null
      alert 'Nenhuma propriedade foi selecionada.'
    else
      $.ajax {
        type: 'PUT',
        url: '/add_property',
        dataType: 'script',
        data: { dataset_id: dataset_id, type: type, property: property }
      }
