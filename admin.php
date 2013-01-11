<?php
defined('URLUPLOADER_PATH') or die('Hacking attempt!');
 
global $template, $page, $conf;

load_language('plugin.lang', URLUPLOADER_PATH);

// +-----------------------------------------------------------------------+
// | URL Uploader tab                                                      |
// +-----------------------------------------------------------------------+
define('PHOTOS_ADD_BASE_URL', get_root_url().'admin.php?page=photos_add');

include_once(PHPWG_ROOT_PATH.'admin/include/functions.php');
include_once(PHPWG_ROOT_PATH.'admin/include/tabsheet.class.php');
include_once(PHPWG_ROOT_PATH.'admin/include/functions_upload.inc.php');

$allowed_extensions = array('jpg','jpeg','png','gif');
$allowed_mimes = array('image/jpeg', 'image/png', 'image/gif');

$tabsheet = new tabsheet();
$tabsheet->set_id('photos_add');
$tabsheet->select('url_uploader');
$tabsheet->assign();


// +-----------------------------------------------------------------------+
// |                             process form                              |
// +-----------------------------------------------------------------------+
if (isset($_GET['processed']))
{
  $category_id = $_POST['category'];
  $image_ids = array();
  $page['thumbnails'] = array();
  
  // SINGLE UPLOAD
  if ($_GET['upload_mode'] == 'single')
  {
    $_POST = array_map('trim', $_POST);
    
    // check empty url
    if (empty($_POST['file_url']))
    {
      $page['errors'][] = l10n('File URL is empty');
    }
    // check remote url
    else if (!url_is_remote($_POST['file_url']))
    {
      $page['errors'][] = l10n('Invalid file URL');
    }
    // check file extension
    else if (!in_array(strtolower(get_extension($_POST['file_url'])), $allowed_extensions))
    {
      $page['errors'][] = l10n('Invalid file type');
    }
    // continue...
    else
    {
      $temp_filename = $conf['data_location'].basename($_POST['file_url']);
      $file = fopen($temp_filename, 'w+');
      $result = fetchRemote($_POST['file_url'], $file);
      fclose($file);
      
      // download failed ?
      if (!$result)
      {
        @unlink($temp_filename);
        $page['errors'][] = l10n('Unable to download file');
      }
      // check mime-type
      else if (!in_array(get_mime($temp_filename, $allowed_mimes[0]), $allowed_mimes))
      {
        @unlink($temp_filename);
        $page['errors'][] = l10n('Invalid file type');
      }
      // continue...
      else
      {
        $image_id = add_uploaded_file(
          $temp_filename, 
          basename($temp_filename), 
          array($category_id), 
          $_POST['level']
          );
        
        if (!empty($_POST['photo_name']))
        {
          single_update(
            IMAGES_TABLE,
            array('name'=>$_POST['photo_name']),
            array('id' => $image_id)
            );
        }
        
        $image_ids = array($image_id);
      }
    }
  }
  // MULTIPLE UPLOAD
  else if ($_GET['upload_mode'] == 'multiple')
  {
    if (isset($_POST['onUploadError']) and is_array($_POST['onUploadError']) and count($_POST['onUploadError']) > 0)
    {
      array_push($page['errors'], sprintf(l10n('%d photos not imported'), count($_POST['onUploadError'])));
      foreach ($_POST['onUploadError'] as $error)
      {
        array_push($page['errors'], $error);
      }
    }
  
    if (isset($_POST['imageIds']) and is_array($_POST['imageIds']) and count($_POST['imageIds']) > 0)
    {
      $image_ids = $_POST['imageIds'];
    }
  }

  // DISPLAY RESULTS
  foreach ($image_ids as $image_id)
  {
    $query = '
SELECT id, file, path
  FROM '.IMAGES_TABLE.'
  WHERE id = '.$image_id.'
;';
    $image_infos = pwg_db_fetch_assoc(pwg_query($query));
    
    $thumbnail = array(
      'file' =>  $image_infos['file'],
      'src' =>   DerivativeImage::thumb_url($image_infos),
      'title' => get_name_from_file($image_infos['file']),
      'link' =>  get_root_url().'admin.php?page=photo-'.$image_id.'&amp;cat_id='.$category_id,
      );

    array_push($page['thumbnails'], $thumbnail);
  }

  if (!empty($page['thumbnails']))
  {
    // nb uploaded
    array_push($page['infos'], sprintf(
      l10n('%d photos uploaded'),
      count($page['thumbnails'])
      ));

    // level
    if (0 != $_POST['level'])
    {
      array_push($page['infos'], sprintf(
        l10n('Privacy level set to "%s"'),
        l10n(sprintf('Level %d', $_POST['level']))
        ));
    }

    // new category count
    $query = '
SELECT COUNT(*)
  FROM '.IMAGE_CATEGORY_TABLE.'
  WHERE category_id = '.$category_id.'
;';
    list($count) = pwg_db_fetch_row(pwg_query($query));
    $category_name = get_cat_display_name_from_id($category_id, 'admin.php?page=album-');
    
    array_push($page['infos'], sprintf(
      l10n('Album "%s" now contains %d photos'),
      '<em>'.$category_name.'</em>',
      $count
      ));
    
    $page['batch_link'] = PHOTOS_ADD_BASE_URL.'&batch='.implode(',', $image_ids);
  }
}


// +-----------------------------------------------------------------------+
// |                             prepare form                              |
// +-----------------------------------------------------------------------+
include(PHPWG_ROOT_PATH.'admin/include/photos_add_direct_prepare.inc.php');

// upload mode
$upload_modes = array('single', 'multiple');
$upload_mode = isset($conf['url_uploader_mode']) ? $conf['url_uploader_mode'] : 'single';

if ( isset($_GET['upload_mode']) and $_GET['upload_mode']!=$upload_mode and in_array($_GET['upload_mode'], $upload_modes) )
{
  $upload_mode = $_GET['upload_mode'];
  conf_update_param('url_uploader_mode', $upload_mode);
}

// what is the upload switch mode
$index_of_upload_mode = array_flip($upload_modes);
$upload_mode_index = $index_of_upload_mode[$upload_mode];
$upload_switch = $upload_modes[ ($upload_mode_index + 1) % 2 ];

$template->assign(array(
  'upload_mode' => $upload_mode,
  'form_action' => URLUPLOADER_ADMIN.'&amp;upload_mode='.$upload_mode.'&amp;processed=1',
  'switch_url' => URLUPLOADER_ADMIN.'&amp;upload_mode='.$upload_switch,
  'another_upload_link' => URLUPLOADER_ADMIN.'&amp;upload_mode='.$upload_mode,
  ));


$template->set_filename('urluploader_content', realpath(URLUPLOADER_PATH . 'template/photos_add.tpl'));

// template vars
$template->assign(array(
  'URLUPLOADER_PATH' => get_root_url() . URLUPLOADER_PATH,
  'URLUPLOADER_ADMIN' => URLUPLOADER_ADMIN,
  ));
  
// send page content
$template->assign_var_from_handle('ADMIN_CONTENT', 'urluploader_content');

?>