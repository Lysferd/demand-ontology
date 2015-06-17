module DatasetHelper

  def select_helper( classes, *args )
    options_for_select(
      classes.collect { | c | [ c.gsub( /_/, ' ' ).titleize, c ] },
      *args
    )
  end

end
