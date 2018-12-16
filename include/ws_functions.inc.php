<?php
defined('URLUPLOADER_PATH') or die('Hacking attempt!');

function urluploader_ws_add_methods($arr)
{
  global $conf;
  $service = &$arr[0];

  $service->addMethod(
    'pwg.images.addRemote',
    'ws_images_addRemote',
    array(
      'file_url' => array(),
      'category' => array('type' => WS_TYPE_ID),
      'name' => array('default' => null),
      'author' => array('default' => null),
      'comment' => array('default' => null),
      'tags' => array(
        'default' => null,
        'flags' => WS_PARAM_ACCEPT_ARRAY,
      ),
      'level' => array(
        'default' => null,
        'maxValue' => $conf['available_permission_levels'],
        'type' => WS_TYPE_INT | WS_TYPE_POSITIVE,
      ),
      'url_in_comment' => array(
        'default' => true,
        'type' => WS_TYPE_BOOL,
      ),
    ),
    'Add image from remote URL.',
    null,
    array('admin_only' => true)
  );
}

function ws_images_addRemote($params, &$service)
{
  global $conf;

  if (!is_admin())
  {
    return new PwgError(401, 'Access denied');
  }

  load_language('plugin.lang', URLUPLOADER_PATH);

  $params = array_map('trim', $params);

  $allowed_extensions = array('jpg', 'jpeg', 'png', 'gif');
  $allowed_mimes = array('image/jpeg', 'image/png', 'image/gif');

  // check empty url
  if (empty($params['file_url']))
  {
    return new PwgError(WS_ERR_INVALID_PARAM, l10n('File URL is empty'));
  }
  // check remote url
  if (!url_is_remote($params['file_url']))
  {
    return new PwgError(WS_ERR_INVALID_PARAM, l10n('Invalid file URL'));
  }
  // check file extension
  if (!in_array(strtolower(get_extension($params['file_url'])), $allowed_extensions))
  {
    return new PwgError(WS_ERR_INVALID_PARAM, l10n('Invalid file type'));
  }

  // download file
  include_once(PHPWG_ROOT_PATH . 'admin/include/functions.php');

  $temp_filename = $conf['data_location'] . basename($params['file_url']);
  $file = fopen($temp_filename, 'w+');
  $result = fetchRemote($params['file_url'], $file);
  fclose($file);

  // download failed ?
  if (!$result)
  {
    @unlink($temp_filename);

    return new PwgError(WS_ERR_INVALID_PARAM, l10n('Unable to download file'));
  }
  // check mime-type
  if (!in_array(get_mime($temp_filename, $allowed_mimes[0]), $allowed_mimes))
  {
    @unlink($temp_filename);

    return new PwgError(WS_ERR_INVALID_PARAM, l10n('Invalid file type'));
  }

  // add photo
  include_once(PHPWG_ROOT_PATH . 'admin/include/functions_upload.inc.php');

  $image_id = add_uploaded_file(
    $temp_filename,
    basename($temp_filename),
    array($params['category'])
  );


  // set properties
  $updates = array();
  foreach (array('level', 'name', 'author', 'comment') as $key)
  {
    if (!empty($params[ $key ]))
    {
      $updates[ $key ] = $params[ $key ];
    }
  }

  if ($params['url_in_comment'] == true)
  {
    $url = urldecode($params['file_url']);
    $url = parse_url($params['file_url']);
    $url = $url['scheme'] . '://' . $url['host'] . $url['path'];
    $link = '<a href="' . $url . '">' . $url . '</a>';

    if (!isset($updates['comment']))
    {
      $updates['comment'] = $link;
    }
    else
    {
      $updates['comment'] .= '<br>' . $link;
    }
  }

  single_update(
    IMAGES_TABLE,
    $updates,
    array('id' => $image_id)
  );


  // set tags
  if (!empty($params['tags']))
  {
    include_once(PHPWG_ROOT_PATH . 'admin/include/functions.php');

    $tag_ids = array();
    if (is_array($params['tags']))
    {
      foreach ($params['tags'] as $tag_name)
      {
        $tag_ids[] = tag_id_from_tag_name($tag_name);
      }
    }
    else
    {
      $tag_names = preg_split('~(?<!\\\),~', $params['tags']);
      foreach ($tag_names as $tag_name)
      {
        $tag_ids[] = tag_id_from_tag_name(preg_replace('#\\\\*,#', ',', $tag_name));
      }
    }

    add_tags($tag_ids, array($image_id));
  }


  // return infos
  $query = '
SELECT id, name, permalink
  FROM ' . CATEGORIES_TABLE . '
  WHERE id = ' . $params['category'] . '
;';
  $category = pwg_db_fetch_assoc(pwg_query($query));

  $url_params = array(
    'image_id' => $image_id,
    'section' => 'categories',
    'category' => $category,
  );

  $query = '
SELECT id, path, name
  FROM ' . IMAGES_TABLE . '
  WHERE id = ' . $image_id . '
;';
  $image_infos = pwg_db_fetch_assoc(pwg_query($query));

  $query = '
SELECT
    COUNT(*) AS nb_photos
  FROM ' . IMAGE_CATEGORY_TABLE . '
  WHERE category_id = ' . $params['category'] . '
;';
  $category_infos = pwg_db_fetch_assoc(pwg_query($query));

  $category_name = get_cat_display_name_from_id($params['category'], null);

  return array(
    'image_id' => $image_id,
    'url' => make_picture_url($url_params),
    'src' => DerivativeImage::thumb_url($image_infos),
    'name' => $image_infos['name'],
    'category' => array(
      'id' => $params['category'],
      'nb_photos' => $category_infos['nb_photos'],
      'label' => $category_name,
    ),
  );
}
