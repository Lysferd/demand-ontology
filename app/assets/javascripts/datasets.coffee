# Place all the behaviors and hooks related to the matching controller here.
# All this logic will automatically be available in application.js.
# You can use CoffeeScript in this file: http://coffeescript.org/

$ ->
  $( 'td.template' ).click ->
    $( 'textarea#query' ).val( $(@).text() )

  $( 'select#property' ).change ->
    values = $('select#property :selected').val().split ':'
    property = $('a[data-property]')
    property.data 'type', values[0]
    property.data 'property', values[1]

  $( 'img.destroy_property' ).click ->
    mode = $(@).data( 'mode' )
    original_property = $(@).data( 'original-property' )
    property = $(@).data( 'property' )
    parent_tr = $(@).parent().parent()
    if not mode
      $( '#individual_property_' + original_property.replace(":", "\\:") ).attr( 'name', "individual[property][#{property}]" )
      $(@).data( 'original-color', parent_tr.css( 'background-color' ) )
      parent_tr.animate { backgroundColor: '#FF3333' }, { easing: "linear", duration: 500 }
    else
      $( '#individual_property_' + original_property.replace(":", "\\:") ).attr( 'name', "individual[property][#{original_property}]" )
      parent_tr.animate { backgroundColor: $(@).data( 'original-color' ) }, { easing: "linear", duration: 500 }

    $(@).data( 'mode', !mode )

  $( 'a[data-property]' ).click ->
    dataset_id = $(@).data 'dataset-id'
    type = $(@).data 'type'
    property = $(@).data 'property'

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