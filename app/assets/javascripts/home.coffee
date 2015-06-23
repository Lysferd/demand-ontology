# Place all the behaviors and hooks related to the matching controller here.
# All this logic will automatically be available in application.js.
# You can use CoffeeScript in this file: http://coffeescript.org/

$ ->
  $( 'form#reasoner select#dataset_id' ).change ->
    $.ajax {
      type: 'PUT',
      url: '/refresh_individual_list',
      dataType: 'script',
      data: { dataset_id: $(@).val() }
    }