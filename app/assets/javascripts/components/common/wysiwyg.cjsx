React = require 'react'

WYSIWYG = React.createClass(
  displayName: 'WYSIWYG'

  propTypes:
    value: React.PropTypes.string
    placeholder: React.PropTypes.string
    autoFocus: React.PropTypes.bool
    onChange: React.PropTypes.func.isRequired
    onBlur: React.PropTypes.func
    onFocus: React.PropTypes.func


  # empty state
  getInitialState: ->
    return {}


  # always return false
  shouldComponentUpdate: ->
    return false


  # create editor on mount
  componentDidMount: ->
    @_createEditor()
    @_bindEditorListeners()

    if @props.autoFocus
      @state.editor.focus();


  # clean up editor on unmount
  componentWillUnmount: ->
    @state.editor.destroy true;


  # create editor
  _createEditor: ->
    CKEDITOR.disableAutoInline = true;
    editor = CKEDITOR.replace(@refs.textarea.getDOMNode(), {
      customConfig: ''
      extraPlugins: 'divarea,autogrow',
      toolbarGroups: [
        { name: 'styles', groups: [ 'styles' ] },
        { name: 'basicstyles', groups: [ 'basicstyles', 'cleanup' ] },
        { name: 'clipboard', groups: [ 'clipboard', 'undo' ] },
        { name: 'editing', groups: [ 'find', 'selection', 'spellchecker', 'editing' ] },
        { name: 'paragraph', groups: [ 'list', 'indent', 'blocks', 'align', 'bidi', 'paragraph' ] },
        { name: 'links', groups: [ 'links' ] },
        { name: 'insert', groups: [ 'insert' ] },
        { name: 'forms', groups: [ 'forms' ] },
        { name: 'tools', groups: [ 'tools' ] },
        { name: 'document', groups: [ 'mode', 'document', 'doctools' ] },
        { name: 'others', groups: [ 'others' ] },
      ],
      removeButtons: 'Underline,Subscript,Undo,Cut,Copy,Redo,Paste,PasteText,PasteFromWord,Scayt,Anchor,SpecialChar,Maximize,Source,RemoveFormat,Superscript,Styles,About',
      removePlugins: 'elementspath',
      resize_enabled: false,
      toolbarLocation: 'bottom'
    })
    @state.editor = editor


  # bind editor event listeners and propagate to prop listeners
  _bindEditorListeners: ->
    @state.editor.on 'change', (e) =>
      console.log("change", e);
      # @props.onChange(e) if @props.onChange

    @state.editor.on 'focus', (e) =>
      console.log("focus!", e);
      @props.onFocus(e) if @props.onFocus

    @state.editor.on 'blur', (e) =>
      console.log("blur!", e);
      @props.onBlur(e) if @props.onBlur


  # render
  render: ->
    <div className='ckeditor'>
      <textarea ref="textarea" placeholder={@props.placeholder || ''}></textarea>
    </div>
)

module.exports = WYSIWYG


# CKEditor config

CKEDITOR.lang['en']={"wsc":{"btnIgnore":"Ignore","btnIgnoreAll":"Ignore All","btnReplace":"Replace","btnReplaceAll":"Replace All","btnUndo":"Undo","changeTo":"Change to","errorLoading":"Error loading application service host: %s.","ieSpellDownload":"Spell checker not installed. Do you want to download it now?","manyChanges":"Spell check complete: %1 words changed","noChanges":"Spell check complete: No words changed","noMispell":"Spell check complete: No misspellings found","noSuggestions":"- No suggestions -","notAvailable":"Sorry, but service is unavailable now.","notInDic":"Not in dictionary","oneChange":"Spell check complete: One word changed","progress":"Spell check in progress...","title":"Spell Checker","toolbar":"Check Spelling"},"undo":{"redo":"Redo","undo":"Undo"},"toolbar":{"toolbarCollapse":"Collapse Toolbar","toolbarExpand":"Expand Toolbar","toolbarGroups":{"document":"Document","clipboard":"Clipboard/Undo","editing":"Editing","forms":"Forms","basicstyles":"Basic Styles","paragraph":"Paragraph","links":"Links","insert":"Insert","styles":"Styles","colors":"Colors","tools":"Tools"},"toolbars":"Editor toolbars"},"table":{"border":"Border size","caption":"Caption","cell":{"menu":"Cell","insertBefore":"Insert Cell Before","insertAfter":"Insert Cell After","deleteCell":"Delete Cells","merge":"Merge Cells","mergeRight":"Merge Right","mergeDown":"Merge Down","splitHorizontal":"Split Cell Horizontally","splitVertical":"Split Cell Vertically","title":"Cell Properties","cellType":"Cell Type","rowSpan":"Rows Span","colSpan":"Columns Span","wordWrap":"Word Wrap","hAlign":"Horizontal Alignment","vAlign":"Vertical Alignment","alignBaseline":"Baseline","bgColor":"Background Color","borderColor":"Border Color","data":"Data","header":"Header","yes":"Yes","no":"No","invalidWidth":"Cell width must be a number.","invalidHeight":"Cell height must be a number.","invalidRowSpan":"Rows span must be a whole number.","invalidColSpan":"Columns span must be a whole number.","chooseColor":"Choose"},"cellPad":"Cell padding","cellSpace":"Cell spacing","column":{"menu":"Column","insertBefore":"Insert Column Before","insertAfter":"Insert Column After","deleteColumn":"Delete Columns"},"columns":"Columns","deleteTable":"Delete Table","headers":"Headers","headersBoth":"Both","headersColumn":"First column","headersNone":"None","headersRow":"First Row","invalidBorder":"Border size must be a number.","invalidCellPadding":"Cell padding must be a positive number.","invalidCellSpacing":"Cell spacing must be a positive number.","invalidCols":"Number of columns must be a number greater than 0.","invalidHeight":"Table height must be a number.","invalidRows":"Number of rows must be a number greater than 0.","invalidWidth":"Table width must be a number.","menu":"Table Properties","row":{"menu":"Row","insertBefore":"Insert Row Before","insertAfter":"Insert Row After","deleteRow":"Delete Rows"},"rows":"Rows","summary":"Summary","title":"Table Properties","toolbar":"Table","widthPc":"percent","widthPx":"pixels","widthUnit":"width unit"},"stylescombo":{"label":"Styles","panelTitle":"Formatting Styles","panelTitle1":"Block Styles","panelTitle2":"Inline Styles","panelTitle3":"Object Styles"},"specialchar":{"options":"Special Character Options","title":"Select Special Character","toolbar":"Insert Special Character"},"sourcearea":{"toolbar":"Source"},"scayt":{"btn_about":"About SCAYT","btn_dictionaries":"Dictionaries","btn_disable":"Disable SCAYT","btn_enable":"Enable SCAYT","btn_langs":"Languages","btn_options":"Options","text_title":"Spell Check As You Type"},"removeformat":{"toolbar":"Remove Format"},"pastetext":{"button":"Paste as plain text","title":"Paste as Plain Text"},"pastefromword":{"confirmCleanup":"The text you want to paste seems to be copied from Word. Do you want to clean it before pasting?","error":"It was not possible to clean up the pasted data due to an internal error","title":"Paste from Word","toolbar":"Paste from Word"},"maximize":{"maximize":"Maximize","minimize":"Minimize"},"magicline":{"title":"Insert paragraph here"},"list":{"bulletedlist":"Insert/Remove Bulleted List","numberedlist":"Insert/Remove Numbered List"},"link":{"acccessKey":"Access Key","advanced":"Advanced","advisoryContentType":"Advisory Content Type","advisoryTitle":"Advisory Title","anchor":{"toolbar":"Anchor","menu":"Edit Anchor","title":"Anchor Properties","name":"Anchor Name","errorName":"Please type the anchor name","remove":"Remove Anchor"},"anchorId":"By Element Id","anchorName":"By Anchor Name","charset":"Linked Resource Charset","cssClasses":"Stylesheet Classes","emailAddress":"E-Mail Address","emailBody":"Message Body","emailSubject":"Message Subject","id":"Id","info":"Link Info","langCode":"Language Code","langDir":"Language Direction","langDirLTR":"Left to Right (LTR)","langDirRTL":"Right to Left (RTL)","menu":"Edit Link","name":"Name","noAnchors":"(No anchors available in the document)","noEmail":"Please type the e-mail address","noUrl":"Please type the link URL","other":"<other>","popupDependent":"Dependent (Netscape)","popupFeatures":"Popup Window Features","popupFullScreen":"Full Screen (IE)","popupLeft":"Left Position","popupLocationBar":"Location Bar","popupMenuBar":"Menu Bar","popupResizable":"Resizable","popupScrollBars":"Scroll Bars","popupStatusBar":"Status Bar","popupToolbar":"Toolbar","popupTop":"Top Position","rel":"Relationship","selectAnchor":"Select an Anchor","styles":"Style","tabIndex":"Tab Index","target":"Target","targetFrame":"<frame>","targetFrameName":"Target Frame Name","targetPopup":"<popup window>","targetPopupName":"Popup Window Name","title":"Link","toAnchor":"Link to anchor in the text","toEmail":"E-mail","toUrl":"URL","toolbar":"Link","type":"Link Type","unlink":"Unlink","upload":"Upload"},"indent":{"indent":"Increase Indent","outdent":"Decrease Indent"},"image":{"alt":"Alternative Text","border":"Border","btnUpload":"Send it to the Server","button2Img":"Do you want to transform the selected image button on a simple image?","hSpace":"HSpace","img2Button":"Do you want to transform the selected image on a image button?","infoTab":"Image Info","linkTab":"Link","lockRatio":"Lock Ratio","menu":"Image Properties","resetSize":"Reset Size","title":"Image Properties","titleButton":"Image Button Properties","upload":"Upload","urlMissing":"Image source URL is missing.","vSpace":"VSpace","validateBorder":"Border must be a whole number.","validateHSpace":"HSpace must be a whole number.","validateVSpace":"VSpace must be a whole number."},"horizontalrule":{"toolbar":"Insert Horizontal Line"},"format":{"label":"Format","panelTitle":"Paragraph Format","tag_address":"Address","tag_div":"Normal (DIV)","tag_h1":"Heading 1","tag_h2":"Heading 2","tag_h3":"Heading 3","tag_h4":"Heading 4","tag_h5":"Heading 5","tag_h6":"Heading 6","tag_p":"Normal","tag_pre":"Formatted"},"fakeobjects":{"anchor":"Anchor","flash":"Flash Animation","hiddenfield":"Hidden Field","iframe":"IFrame","unknown":"Unknown Object"},"elementspath":{"eleLabel":"Elements path","eleTitle":"%1 element"},"contextmenu":{"options":"Context Menu Options"},"clipboard":{"copy":"Copy","copyError":"Your browser security settings don't permit the editor to automatically execute copying operations. Please use the keyboard for that (Ctrl/Cmd+C).","cut":"Cut","cutError":"Your browser security settings don't permit the editor to automatically execute cutting operations. Please use the keyboard for that (Ctrl/Cmd+X).","paste":"Paste","pasteArea":"Paste Area","pasteMsg":"Please paste inside the following box using the keyboard (<strong>Ctrl/Cmd+V</strong>) and hit OK","securityMsg":"Because of your browser security settings, the editor is not able to access your clipboard data directly. You are required to paste it again in this window.","title":"Paste"},"button":{"selectedLabel":"%1 (Selected)"},"blockquote":{"toolbar":"Block Quote"},"basicstyles":{"bold":"Bold","italic":"Italic","strike":"Strikethrough","subscript":"Subscript","superscript":"Superscript","underline":"Underline"},"about":{"copy":"Copyright &copy; $1. All rights reserved.","dlgTitle":"About CKEditor","help":"Check $1 for help.","moreInfo":"For licensing information please visit our web site:","title":"About CKEditor","userGuide":"CKEditor User's Guide"},"editor":"Rich Text Editor","editorPanel":"Rich Text Editor panel","common":{"editorHelp":"Press ALT 0 for help","browseServer":"Browse Server","url":"URL","protocol":"Protocol","upload":"Upload","uploadSubmit":"Send it to the Server","image":"Image","flash":"Flash","form":"Form","checkbox":"Checkbox","radio":"Radio Button","textField":"Text Field","textarea":"Textarea","hiddenField":"Hidden Field","button":"Button","select":"Selection Field","imageButton":"Image Button","notSet":"<not set>","id":"Id","name":"Name","langDir":"Language Direction","langDirLtr":"Left to Right (LTR)","langDirRtl":"Right to Left (RTL)","langCode":"Language Code","longDescr":"Long Description URL","cssClass":"Stylesheet Classes","advisoryTitle":"Advisory Title","cssStyle":"Style","ok":"OK","cancel":"Cancel","close":"Close","preview":"Preview","resize":"Resize","generalTab":"General","advancedTab":"Advanced","validateNumberFailed":"This value is not a number.","confirmNewPage":"Any unsaved changes to this content will be lost. Are you sure you want to load new page?","confirmCancel":"You have changed some options. Are you sure you want to close the dialog window?","options":"Options","target":"Target","targetNew":"New Window (_blank)","targetTop":"Topmost Window (_top)","targetSelf":"Same Window (_self)","targetParent":"Parent Window (_parent)","langDirLTR":"Left to Right (LTR)","langDirRTL":"Right to Left (RTL)","styles":"Style","cssClasses":"Stylesheet Classes","width":"Width","height":"Height","align":"Alignment","alignLeft":"Left","alignRight":"Right","alignCenter":"Center","alignJustify":"Justify","alignTop":"Top","alignMiddle":"Middle","alignBottom":"Bottom","alignNone":"None","invalidValue":"Invalid value.","invalidHeight":"Height must be a number.","invalidWidth":"Width must be a number.","invalidCssLength":"Value specified for the \"%1\" field must be a positive number with or without a valid CSS measurement unit (px, %, in, cm, mm, em, ex, pt, or pc).","invalidHtmlLength":"Value specified for the \"%1\" field must be a positive number with or without a valid HTML measurement unit (px or %).","invalidInlineStyle":"Value specified for the inline style must consist of one or more tuples with the format of \"name : value\", separated by semi-colons.","cssLengthTooltip":"Enter a number for a value in pixels or a number with a valid CSS unit (px, %, in, cm, mm, em, ex, pt, or pc).","unavailable":"%1<span class=\"cke_accessibility\">, unavailable</span>"}};
CKEDITOR.skin.loadPart = (p, cb) -> cb()
CKEDITOR.stylesSet.add( 'default', [
  # These styles are already available in the "Format" combo ("format" plugin),
  # so they are not needed here by default. You may enable them to avoid
  # placing the "Format" combo in the toolbar, maintaining the same features.

  # { name: 'Paragraph',    element: 'p' },
  # { name: 'Heading 1',    element: 'h1' },
  # { name: 'Heading 2',    element: 'h2' },
  # { name: 'Heading 3',    element: 'h3' },
  # { name: 'Heading 4',    element: 'h4' },
  # { name: 'Heading 5',    element: 'h5' },
  # { name: 'Heading 6',    element: 'h6' },
  # { name: 'Preformatted Text',element: 'pre' },
  # { name: 'Address',      element: 'address' },


  { name: 'Italic Title',   element: 'h2', styles: { 'font-style': 'italic' } },
  { name: 'Subtitle',     element: 'h3', styles: { 'color': '#aaa', 'font-style': 'italic' } },
  {
    name: 'Special Container',
    element: 'div',
    styles: {
      padding: '5px 10px',
      background: '#eee',
      border: '1px solid #ccc'
    }
  },


  # These are core styles available as toolbar buttons. You may opt enabling
  # some of them in the Styles combo, removing them from the toolbar.
  # (This requires the "stylescombo" plugin)

  # { name: 'Strong',     element: 'strong', overrides: 'b' },
  # { name: 'Emphasis',     element: 'em' , overrides: 'i' },
  # { name: 'Underline',    element: 'u' },
  # { name: 'Strikethrough',  element: 'strike' },
  # { name: 'Subscript',    element: 'sub' },
  # { name: 'Superscript',    element: 'sup' },

  { name: 'Marker',     element: 'span', attributes: { 'class': 'marker' } },

  { name: 'Big',        element: 'big' },
  { name: 'Small',      element: 'small' },
  { name: 'Typewriter',   element: 'tt' },

  { name: 'Computer Code',  element: 'code' },
  { name: 'Keyboard Phrase',  element: 'kbd' },
  { name: 'Sample Text',    element: 'samp' },
  { name: 'Variable',     element: 'var' },

  { name: 'Deleted Text',   element: 'del' },
  { name: 'Inserted Text',  element: 'ins' },

  { name: 'Cited Work',   element: 'cite' },
  { name: 'Inline Quotation', element: 'q' },

  { name: 'Language: RTL',  element: 'span', attributes: { 'dir': 'rtl' } },
  { name: 'Language: LTR',  element: 'span', attributes: { 'dir': 'ltr' } },

  # /* Object Styles */

  {
    name: 'Styled image (left)',
    element: 'img',
    attributes: { 'class': 'left' }
  },

  {
    name: 'Styled image (right)',
    element: 'img',
    attributes: { 'class': 'right' }
  },

  {
    name: 'Compact table',
    element: 'table',
    attributes: {
      cellpadding: '5',
      cellspacing: '0',
      border: '1',
      bordercolor: '#ccc'
    },
    styles: {
      'border-collapse': 'collapse'
    }
  },

  { name: 'Borderless Table',   element: 'table', styles: { 'border-style': 'hidden', 'background-color': '#E6E6FA' } },
  { name: 'Square Bulleted List', element: 'ul',    styles: { 'list-style-type': 'square' } }
] );

CKEDITOR.plugins.add("divarea", {
  afterInit: (a) ->
    a.addMode("wysiwyg", (c) ->
      b=CKEDITOR.dom.element.createFromHtml('\x3cdiv class\x3d"cke_wysiwyg_div cke_reset cke_enable_context_menu" hidefocus\x3d"true"\x3e\x3c/div\x3e');
      a.ui.space("contents").append(b);
      b=a.editable(b);
      b.detach=CKEDITOR.tools.override(b.detach, (a) ->
        return () ->
          a.apply(this,arguments);
          this.remove()
      );
      a.setData(a.getData(1),c);
      a.fire("contentDom")
    )
});

h = (a) ->
  `var h`
  l = undefined
  d = undefined
  n = undefined
  c = undefined
  e = undefined
  h = a.config.autoGrow_bottomSpace or 0
  r = if undefined != a.config.autoGrow_minHeight then a.config.autoGrow_minHeight else 200
  p = a.config.autoGrow_maxHeight or Infinity
  k = !a.config.autoGrow_maxHeight

  m = ->
    d = a.document
    n = d[if CKEDITOR.env.ie then 'getBody' else 'getDocumentElement']()
    c = if CKEDITOR.env.quirks then d.getBody() else d.getDocumentElement()
    e = CKEDITOR.dom.element.createFromHtml('<span style="margin:0;padding:0;border:0;clear:both;width:1px;height:1px;display:block;">' + (if CKEDITOR.env.webkit then '&nbsp;' else '') + '</span>', d)
    return

  f = ->
    k and c.setStyle('overflow-y', 'hidden')
    g = a.window.getViewPaneSize().height
    b = undefined
    n.append e
    b = e.getDocumentPosition(d).y + e.$.offsetHeight
    e.remove()
    b += h
    b = Math.max(b, r)
    b = Math.min(b, p)
    b != g and l != b and b = a.fire('autoGrow',
      currentHeight: g
      newHeight: b).newHeight
    a.resize(a.container.getStyle('width'), b, !0)
    l = b
    k or (if b < p and c.$.scrollHeight > c.$.clientHeight then c.setStyle('overflow-y', 'hidden') else c.removeStyle('overflow-y'))
    return

  a.addCommand 'autogrow',
    exec: f
    modes: wysiwyg: 1
    readOnly: 1
    canUndo: !1
    editorFocus: !1
  t =
    contentDom: 1
    key: 1
    selectionChange: 1
    insertElement: 1
    mode: 1
  q = undefined
  for q of t
    a.on q, (g) ->
      'wysiwyg' == g.editor.mode and setTimeout((->
        b = a.getCommand('maximize')
        if !a.window or b and b.state == CKEDITOR.TRISTATE_ON then (l = null) else f()
        k or f()
        return
      ), 100)
      return
  a.on 'afterCommandExec', (a) ->
    'maximize' == a.data.name and 'wysiwyg' == a.editor.mode and (if a.data.command.state == CKEDITOR.TRISTATE_ON then c.removeStyle('overflow-y') else f())
    return
  a.on 'contentDom', m
  m()
  a.config.autoGrow_onStartup and a.execCommand('autogrow')
  return

CKEDITOR.plugins.add 'autogrow', init: (a) ->
  if a.elementMode != CKEDITOR.ELEMENT_MODE_INLINE
    a.on 'instanceReady', ->
      if a.editable().isInline() then a.ui.space('contents').setStyle('height', 'auto') else h(a)
      return
  return
