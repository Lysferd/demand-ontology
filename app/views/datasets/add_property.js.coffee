$('form table tr:last').before(
  <% if @individuals %>
  '<%=j render 'add_property_field', type: @type, property: @property,
      individuals: select_helper(@individuals) %>'
  <% else %>
  '<%=j render 'add_property_field', type: @type, property: @property %>'
  <% end %>
)

$('img.remove_property').click -> $(@).parent().parent().remove()