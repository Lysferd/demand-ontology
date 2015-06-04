# Encoding: UTF-8

module HomeHelper

  def button_get( name = nil, options = nil, html_options = { }, &block )
    html_options[:method] = :get
    name = t( name ) if name.kind_of?( Symbol )
    return button_to( name, options, html_options, &block )
  end
  
  def button_delete( name = nil, options = nil, html_options = { }, &block )
    html_options[:method] = :delete
    html_options[:data] = { confirm: 'Deseja realizar a operação?' }
    name = t( name ) if name.kind_of?( Symbol )
    return button_to( name, options, html_options, &block )
  end

end
