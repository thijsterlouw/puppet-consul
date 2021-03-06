# == Class consul::intall
#
# Installs consule based in the parameters from init
#
class consul::install {

  if $consul::data_dir {
    file { $consul::data_dir:
      ensure => 'directory',
      owner  => $consul::user,
      group  => $consul::group,
      mode   => '0755',
    }
  }

  if $consul::install_method == 'url' {

    $version = $consul::version
    $consul_archive_target = "consul_${version}.zip"
    $consul_web_ui_archive_target = "consul_web_ui_${version}.zip"

    if $::operatingsystem != 'darwin' {
      ensure_packages(['unzip'])
    }
    staging::file { $consul_archive_target:
      source => $consul::download_url
    } ->
    file { "${consul::bin_dir}/consul_${version}/":
      ensure => 'directory',
      owner  => 'root',
      group  => 0,
      mode   => '0755',
    } ->
    staging::extract { $consul_archive_target:
      target  => "${consul::bin_dir}/consul_${version}/",
      creates => "${consul::bin_dir}/consul_${version}/consul",
    } ->
    file { "${consul::bin_dir}/consul":
      owner  => 'root',
      group  => 0, # 0 instead of root because OS X uses "wheel".
      mode   => '0555',
      target => "${consul::bin_dir}/consul_${version}/consul",
      notify => Class['consul::run_service'],
    }


    if ($consul::ui_dir and $consul::data_dir) {
      file { "${consul::data_dir}/${version}_web_ui":
        ensure => 'directory',
        owner  => 'root',
        group  => 0, # 0 instead of root because OS X uses "wheel".
        mode   => '0755',
      } ->
      staging::deploy { $consul_web_ui_archive_target:
        source  => $consul::ui_download_url,
        target  => "${consul::data_dir}/${version}_web_ui",
        creates => "${consul::data_dir}/${version}_web_ui/dist",
      }
      file { $consul::ui_dir:
        ensure => 'symlink',
        target => "${consul::data_dir}/${version}_web_ui/dist",
      }
    }

  } elsif $consul::install_method == 'package' {

    package { $consul::package_name:
      ensure => $consul::package_ensure,
    }

    if $consul::ui_dir {
      package { $consul::ui_package_name:
        ensure => $consul::ui_package_ensure,
      }
    }

  } else {
    fail("The provided install method ${consul::install_method} is invalid")
  }

  if $consul::manage_user {
    user { $consul::user:
      ensure => 'present',
    }
  }
  if $consul::manage_group {
    group { $consul::group:
      ensure => 'present',
    }
  }
}
