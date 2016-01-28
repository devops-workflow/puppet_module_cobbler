define cobbler::repo (
$arch           = 'x86_64',
$breed          = 'yum',
$comment        = "${title} repo",
$keep_updated   = 'Y',
$mirror_locally = 'Y',
$mirror,
$priority       = '99',
$proxy          = '',
) {

  exec { "add ${title} repo": 
    command  => "${cobbler::binary} repo add \
      --name \"${title}\"\
      --arch \"${arch}\"\
      --breed \"${breed}\"\
      --clobber\
      --comment \"$comment\"\
      --keep-updated \"${keep_updated}\"\
      --mirror \"${mirror}\"\
      --mirror-locally \"${mirror_locally}\"\
      --proxy \"${proxy}\"\
      --priority \"${priority}\"\
     ",
#    unless   => "${cobbler::binary} repo report --name ${title}",
    require  => Service[$cobbler::service],
  }
}
