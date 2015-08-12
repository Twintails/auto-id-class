# ----------------------------------------------------------------------------
#  auto id class
# ----------------------------------------------------------------------------
{CompositeDisposable} = require 'atom'

module.exports = AutoIdClass =

  subscriptions: null


  ###
  # Activate
  # Subscribe key mappings to methods
  ###
  activate: (state) ->
    @subscriptions = new CompositeDisposable
    @subscriptions.add atom.commands.add 'atom-text-editor',
      'auto-id-class:insert_id_attribute': => @insert_id_attribute()
    @subscriptions.add atom.commands.add 'atom-text-editor',
      'auto-id-class:insert_class_attribute': => @insert_class_attribute()


  ###
  # Insert ID attribute method
  ###
  insert_id_attribute: ->
    if @cursor_inside_html_tag()
      @insert_attribute('id')
    else
      event.abortKeyBinding()


  ###
  # Insert Class attribute method
  ###
  insert_class_attribute: ->
    if @cursor_inside_html_tag()
      @insert_attribute('class')
    else
      event.abortKeyBinding()


  ###
  # Check if cursor is within an HTML tag
  # returns {Bool}
  ###
  cursor_inside_html_tag: ->

    # Get editor and cursor
    editor = atom.workspace.getActiveTextEditor()
    cursor = editor.cursors[0] # TODO: Support multiple cursors

    # Get cursos position and scope
    cursorBufferPos = cursor.getBufferPosition()
    cursorScopes = editor.scopeDescriptorForBufferPosition(cursorBufferPos).scopes

    # Checking scope strings against the scope descriptions -- Is there a cleaner way?
    # Check if cursor within HTML scope description.
    if cursorScopes[0] && cursorScopes[0].search('text.html') < 0
      return false

    # Within tag types:
    if cursorScopes[1] && cursorScopes[1].search('meta\.tag\..*\.html') < 0
      return false

    # Invalid cursor scope positions:
    switch cursorScopes[2]
      when "string.quoted.double.html" then return false
      when "entity.other.attribute-name.html" then return false

    # Finally is the cursor truly within an html tag? Check for < and > chars

    # Get the cursors current column and line of buffer for evaluation
    cursorColumn = cursorBufferPos.column
    bufferLine = cursor.getCurrentBufferLine()
    codeLeftOfColumn = bufferLine.substring(0, cursorColumn)
    codeRightOfColumn = bufferLine.substring(cursorColumn, bufferLine.length)

    # Is the cursor within HTML opening and closing tags? Exit if not
    if(codeLeftOfColumn.lastIndexOf('<') <= codeLeftOfColumn.lastIndexOf('>'))
      return false
    if(codeRightOfColumn.lastIndexOf('>') <= codeRightOfColumn.lastIndexOf('<'))
      return false

    # Is the cursor already within "quotes"?
    # Test by looking for a quote after an =
    if(codeLeftOfColumn.lastIndexOf('"') > 0)
      if(codeLeftOfColumn.lastIndexOf('"') < codeLeftOfColumn.lastIndexOf('=') + 2)
        return false

    # TODO: check if cursor within { curly braces } within an html tag and return false
    # as this can be very annoying when trying to use . and # within Angular tags

    # Made it this far? Must be worthy of a class or id attribute
    return true


  ###
  # Insert attribute by string
  ###
  insert_attribute: (attrType) ->
    editor = atom.workspace.getActiveTextEditor()

    # Insert space, attribute and =""
    # TODO: Don't add space char if already present
    editor.insertText ' ' + attrType + '=""'

    # Move cursor back into quotes "|"
    atom.workspace.getActiveTextEditor().cursors[0].moveLeft(1)


  ###
  # Deactivate
  ###
  deactivate: ->
    @subscriptions.dispose()
