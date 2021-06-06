#!/usr/bin/env python

"""Script/hack to run `indico setup wizard` without interactive prompts.

This will be executed by Docker when building image to create all directories
and links and generate default configuration.
"""

import argparse
import os
import indico.cli.setup


def _confirm(message, default=False, abort=False, help=None):
    """Method to monkey-patch indico.cli.setup._confirm
    """
    return False

orig_confirm = indico.cli.setup._confirm
indico.cli.setup._confirm = _confirm

def main():

    parser = argparse.ArgumentParser(description='Silent indico setup wizard')
    parser.add_argument("--root-path", metavar="PATH", default="/home/indico/indico",
                        help="Path to install all files.")
    parser.add_argument("--dst-path", metavar="PATH", default="/opt/indico",
                        help="Path where files will be copied later.")
    args = parser.parse_args()

    wizard = indico.cli.setup.SetupWizard()

    wizard.root_path = args.root_path
    wizard.data_root_path = wizard.root_path
    wizard.config_dir_path = os.path.join(wizard.root_path, "etc")
    wizard.config_path = os.path.join(wizard.config_dir_path, "indico.conf")
    wizard.indico_url = "https://indico.example.com/"
    wizard.db_uri = "postgres://indico:password@indico-db/indico"
    wizard.redis_uri_celery = "redis://indico-redis:6379/0"
    wizard.redis_uri_cache = "redis://indico-redis:6379/1"
    wizard.contact_email = "indico@example.com"
    wizard.admin_email = "indico@example.com"
    wizard.noreply_email = "noreply@example.com"
    wizard.smtp_host = "127.0.0.1"
    wizard.smtp_port = 25
    wizard.smtp_user = ""
    wizard.smtp_password = ""
    wizard.default_locale = "en_GB"
    wizard.default_timezone = "America/Los_Angeles"
    wizard.rb_active = True
    wizard.old_archive_dir = ""

    wizard._check_directories()
    wizard._setup()

    # still needs some patching of few parameters
    lines = open(wizard.config_path).read().split('\n')
    params = ("CACHE_DIR", "TEMP_DIR", "LOG_DIR", "ASSETS_DIR", "STORAGE_BACKENDS")
    with open(wizard.config_path, "w") as cfg:
        for line in lines:
            if line.startswith(params):
                line = line.replace(args.root_path, args.dst_path)
            cfg.write(line + '\n')

if __name__ == "__main__":
    main()
