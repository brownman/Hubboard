class HEventPanel < EventPanel
  def body= event
    @contents_html.page = "<h1>#{event[:title]}</h1>#{event[:content]}"
    @user_name.label = event[:author][:name]
  end
end
