{combine_css path=$URLUPLOADER_PATH|@cat:"template/style.css"}
{combine_script id="URI" load="footer" path=$URLUPLOADER_PATH|@cat:"template/URI.min.js"}
{combine_script id="createTextareaWithLines" load="footer" path=$URLUPLOADER_PATH|@cat:"template/createTextareaWithLines.js"}

{if $upload_mode == 'multiple'}
{combine_script id='jquery.ajaxmanager' load='footer' path='themes/default/js/plugins/jquery.ajaxmanager.js'}
{combine_script id='jquery.jgrowl' load='footer' require='jquery' path='themes/default/js/plugins/jquery.jgrowl_minimized.js' }
{combine_script id='jquery.ui.progressbar' load='footer'}
{combine_css path="admin/themes/default/uploadify.jGrowl.css"}
{/if}

{include file='include/colorbox.inc.tpl'}
{include file='include/add_album.inc.tpl'}


{footer_script}
var allowed_extensions = new Array('jpeg','jpg','png','gif');
var errorHead   = '{'ERROR'|@translate|@escape:'javascript'}';
var errorMsg    = '{'an error happened'|@translate|@escape:'javascript'}';

var lang = new Array();
lang['Invalid file URL'] = '{'Invalid file URL'|@translate|@escape:'javascript'}';
lang['Invalid file type'] = '{'Invalid file type'|@translate|@escape:'javascript'}';
lang['File URL is empty'] = '{'File URL is empty'|@translate|@escape:'javascript'}';
lang['Unable to download file'] = '{'Unable to download file'|@translate|@escape:'javascript'}';
lang['Pending'] = '{'Pending'|@translate|@escape:'javascript'}';
lang['Delete this item'] = '{'Delete this item'|@translate|@escape:'javascript'}';

{literal}
jQuery("#hideErrors").click(function() {
    jQuery("#formErrors").hide();
    return false;
  });
  
jQuery("#uploadWarningsSummary a.showInfo").click(function() {
    jQuery("#uploadWarningsSummary").hide();
    jQuery("#uploadWarnings").show();
    return false;
  });
  
jQuery("#showPermissions").click(function() {
    jQuery(this).parent(".showFieldset").hide();
    jQuery("#permissions").show();
    return false;
  });
{/literal}


{* <!-- MULTIPLE UPLOAD --> *}
{if $upload_mode == 'multiple'}
{literal}
function checkUploadStart() {
  var nbErrors = 0;
  
  jQuery("#formErrors").hide();
  jQuery("#formErrors li").hide();

  if (jQuery("#albumSelect option:selected").length == 0) {
    jQuery("#formErrors #noAlbum").show();
    nbErrors++;
  }
  
  var nbFiles = jQuery("table#links tr.pending").length;
  
  if (nbFiles == 0) {
    jQuery("#formErrors #noPhoto").show();
    nbErrors++;
  }

  if (nbErrors != 0) {
    jQuery("#formErrors").show();
    return false;
  }
  else {
    return true;
  }
}

function trim (myString) {
  return myString.replace(/^\s+/g,'').replace(/\s+$/g,'')
}

jQuery("input[name='add_links']").click(function() {
  $input = jQuery("textarea#urls");
  
  if ($input.val() != "") {
    jQuery("table#links").show();
    
    lines = $input.val().split('\n');
    $input.val("");
    
    for (i in lines) {
      line = lines[i].split('|');
      item = new Array;
      
      // no name given
      if (line.length == 1) {
        uri = new URI(trim(line[0]));
        item['name'] = "";
      }
      // name given
      else {
        uri = new URI(trim(line[1]));
        item['name']= trim(line[0]);
      }
      
      uri.fragment("");
      item['url'] = uri.href();
      item['short_url'] = item['url'];
      
      // shortened url for display
      if (item['url'].length > 40) {
        item['short_url'] = item['url'].substring(0, 17) + ' ... ' + item['url'].substring(item['url'].length-17);
      }
      
      // check if consistent url
      if (uri.is("relative")) {
        item['status'] = 'error';
        item['info'] = lang['Invalid file URL'];
      }
      else {
        // check if good extension
        if (allowed_extensions.indexOf(uri.suffix().toLowerCase()) == -1) {
          item['status'] = 'error';
          item['info'] = lang['Invalid file type'];
        }
        else {
          item['status'] = 'pending';
          item['info'] = lang['Pending'];
        }
      }
      
      // add link to table
      jQuery("table#links tbody").append('<tr class="'+ item['status'] + '" data-name="'+ item['name'] +'" data-url="'+ item['url'] +'">'+
        '<td>'+ item['name'] +'</td>'+
        '<td><a href="'+ item['url'] +'">'+ item['short_url'] +'</a></td>'+
        '<td>'+ item['info'] +'</td>'+
        '<td><a class="delete" title="'+ lang['Delete this item'] +'">&nbsp;</a></td>'+
      '</tr>');
    }
  }
  
  $input.focus();
  return false;
});

jQuery("table#links").on("click", "a.delete", function() {
  $(this).parents("tr").remove();
  jQuery("textarea#urls").focus();
});

/* <!-- AJAX MANAGER --> */
var import_done = 0;
var import_selected = 0;
var queuedManager = jQuery.manageAjax.create('queued', {
  queue: true,  
  maxRequests: 1
});

function performImport(file_url, category, name, level, $target) {
  queuedManager.add({
    type: 'GET',
    dataType: 'json',
    url: 'ws.php',
    data: { method: 'pwg.images.addRemote', file_url: file_url, category: category, name: name, level: level, format: 'json' },
    success: function(data) {
      if (data['stat'] == 'ok') {
        $target.remove();
        jQuery("#uploadedPhotos").parent("fieldset").show();
        jQuery("#uploadedPhotos").prepend('<img src="'+ data['result']['thumbnail_url'] +'" class="thumbnail"> ');
        jQuery("#uploadForm").append('<input type="hidden" name="imageIds[]" value="'+ data['result']['image_id'] +'">');
      }
      else {
        jQuery.jGrowl(name +' : '+ lang[data['message']], { 
          theme: 'error', 
          header: errorHead, 
          sticky: true 
          });
          
        $target.children("td:nth-child(3)").html(lang[data['message']]);
        jQuery("#uploadForm").append('<input type="hidden" name="onUploadError[]" value="'+ file_url +' : '+ lang[data['message']] +'">');
      }
      
      import_done++;
      jQuery("#progressbar").progressbar({value: import_done});
      jQuery("#progressCurrent").text(import_done);
      
      if (import_done == import_selected) {
        $("#uploadForm").submit();
      }
    },
    error: function(data) {
      jQuery.jGrowl(name +' : '+ errorMsg, { 
        theme: 'error', 
        header: errorHead, 
        sticky: true 
        });
      
      $target.children("td:nth-child(3)").html(errorMsg);
    }
  });
}

jQuery("input[name='submit_upload']").click(function() {
  if (!checkUploadStart()) {
    return false;
  }
  
  import_selected = jQuery("table#links tr.pending").length;
  
  jQuery("table#links a.delete").hide();
  
  jQuery("#progressbar").progressbar({max: import_selected, value:0});
  jQuery("#progressMax").text(import_selected);
  jQuery("#progressCurrent").text(0);
  jQuery("#uploadProgress").show();
  
  jQuery("table#links tr.pending").each(function() {
    performImport(
      $(this).data('url'),
      $("select[name=category] option:selected").val(),
      $(this).data('name'),
      $("select[name=level] option:selected").val(),
      $(this)
      );
  });
    
  return false;
});

createTextAreaWithLines('urls');
{/literal}


{* <!-- SINGLE UPLOAD --> *}
{else}
{literal}
function checkUploadStart() {
  var nbErrors = 0;
  
  jQuery("#formErrors").hide();
  jQuery("#formErrors li").hide();

  if (jQuery("#albumSelect option:selected").length == 0) {
    jQuery("#formErrors #noAlbum").show();
    nbErrors++;
  }
  
  if (jQuery("input[name='file_url']").val() == "") {
    jQuery("#formErrors #urlEmpty").show();
    nbErrors++;
  }
  else {
    uri = new URI(jQuery("input[name='file_url']").val());
    if (uri.is('relative')) {
      jQuery("#formErrors #urlError").show();
      nbErrors++;
    }
    else if (allowed_extensions.indexOf(uri.suffix().toLowerCase()) == -1) {
      jQuery("#formErrors #typeError").show();
      nbErrors++;
    }
  }

  if (nbErrors != 0) {
    jQuery("#formErrors").show();
    return false;
  }
  else {
    return true;
  }
}

jQuery("input[name='submit_upload']").click(function() {
  return checkUploadStart();
});
{/literal}
{/if}

{/footer_script}


{html_head}{literal}
<style type="text/css">
a.delete {
  background:url('admin/include/uploadify/cancel.png');
}
</style>
{/literal}{/html_head}


<div class="titrePage">
  <h2>{'Upload Photos'|@translate} {$TABSHEET_TITLE}</h2>
</div>

<div id="photosAddContent">

{if count($setup_errors) > 0}
<div class="errors">
  <ul>
  {foreach from=$setup_errors item=error}
    <li>{$error}</li>
  {/foreach}
  </ul>
</div>
{else}

  {if count($setup_warnings) > 0}
<div class="warnings">
  <ul>
    {foreach from=$setup_warnings item=warning}
    <li>{$warning}</li>
    {/foreach}
  </ul>
  <div class="hideButton" style="text-align:center"><a href="{$hide_warnings_link}">{'Hide'|@translate}</a></div>
</div>
  {/if}
  
{if !empty($thumbnails)}
<fieldset>
  <legend>{'Uploaded Photos'|@translate}</legend>
  <div>
  {foreach from=$thumbnails item=thumbnail}
    <a href="{$thumbnail.link}" class="externalLink">
      <img src="{$thumbnail.src}" alt="{$thumbnail.file}" title="{$thumbnail.title}" class="thumbnail">
    </a>
  {/foreach}
  </div>
  <p id="batchLink"><a href="{$batch_link}">{$batch_label}</a></p>
</fieldset>
<p style="margin:10px"><a href="{$another_upload_link}">{'Add another set of photos'|@translate}</a></p>
{else}

<div id="formErrors" class="errors" style="display:none">
  <ul>
    <li id="noAlbum">{'Select an album'|@translate}</li>
    <li id="noPhoto">{'Select at least one photo'|@translate}</li>
    <li id="urlEmpty">{'File URL is empty'|@translate}</li>
    <li id="urlError">{'Invalid file URL'|@translate}</li>
    <li id="typeError">{'Invalid file type'|@translate}</li>
  </ul>
  <div class="hideButton" style="text-align:center"><a href="#" id="hideErrors">{'Hide'|@translate}</a></div>
</div>

<form id="uploadForm" enctype="multipart/form-data" method="post" action="{$form_action}" class="properties">
    <fieldset>
      <legend>{'Drop into album'|@translate}</legend>

      <span id="albumSelection"{if count($category_options) == 0} style="display:none"{/if}>
      <select id="albumSelect" name="category">
        {html_options options=$category_options selected=$category_options_selected}
      </select>
      <br>{'... or '|@translate}</span><a href="#" class="addAlbumOpen" title="{'create a new album'|@translate}">{'create a new album'|@translate}</a>
      
    </fieldset>

    <fieldset>
      <legend>{'Select files'|@translate}</legend>
      
      <p id="uploadWarningsSummary">
        {'Allowed file types: %s.'|@translate|@sprintf:$upload_file_types}
      {if isset($max_upload_resolution)}
        {$max_upload_resolution}Mpx
        <a class="showInfo" title="{'Learn more'|@translate}">i</a>
      {/if}
      </p>

      <p id="uploadWarnings">
        {'Allowed file types: %s.'|@translate|@sprintf:$upload_file_types}
      {if isset($max_upload_resolution)}
        {'Approximate maximum resolution: %dM pixels (that\'s %dx%d pixels).'|@translate|@sprintf:$max_upload_resolution:$max_upload_width:$max_upload_height}
      {/if}
      </p>

{* <!-- SINGLE UPLOAD --> *}
{if $upload_mode == 'single'}
      <ul>
        <li>
          <label>
            <span class="property">{'File URL'|@translate}</span>
            <input type="text" name="file_url" size="70">
          </label>
        </li>
        <li>
          <label>
            <span class="property">{'Photo name'|@translate}</span>
            <input type="text" name="photo_name" size="40">
          </label>
        </li>
      </ul>      
      
      <p id="uploadModeInfos">{'Want to upload many files? Try the <a href="%s">multiple uploader</a> instead.'|@translate|@sprintf:$switch_url}</p>

{* <!-- MULTIPLE UPLOAD --> *}
{else}

      <table id="links" class="table2" style="display:none;">
        <thead>
          <tr class="throw">
            <th style="width:150px;">{'Photo name'|@translate}</th>
            <th>{'File URL'|@translate}</th>
            <th style="width:150px;">{'Status'|@translate}</th>
            <th style="width:20px;"></th>
          </tr>
        </thead>
        <tbody>
        </tbody>
      </table>
      
      <p>
        {'One link by line, separate photo name and url with a &laquo; | &raquo;. Photo name is optional.'|@translate}
        <br>
        <textarea id="urls"></textarea>
      </p>
      <input type="submit" name="add_links" value="{'Add links'|@translate}">
      
      <p id="uploadModeInfos">{'Multiple uploader doesn\'t work? Try the <a href="%s">single uploader</a> instead.'|@translate|@sprintf:$switch_url}</p>
{/if}
    </fieldset>

    <p class="showFieldset"><a id="showPermissions" href="#">{'Manage Permissions'|@translate}</a></p>

    <fieldset id="permissions" style="display:none">
      <legend>{'Who can see these photos?'|@translate}</legend>

      <select name="level" size="1">
        {html_options options=$level_options selected=$level_options_selected}
      </select>
    </fieldset>
    
    <p>
      <input class="submit" type="submit" name="submit_upload" value="{'Start Upload'|@translate}">
    </p>
</form>

<div id="uploadProgress" style="display:none">
{'Photo %s of %s'|@translate|@sprintf:'<span id="progressCurrent">1</span>':'<span id="progressMax">10</span>'}
<br>
<div id="progressbar"></div>
</div>

<fieldset style="display:none">
  <legend>{'Uploaded Photos'|@translate}</legend>
  <div id="uploadedPhotos"></div>
</fieldset>

{/if} {* empty($thumbnails) *}
{/if} {* $setup_errors *}

<br>
</div> <!-- photosAddContent -->