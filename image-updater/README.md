# image-updater/

Holds this app's argocd-image-updater `ImageUpdater` CR. The directory exists
from the first commit so `repo-protections` treats this as a CD repo and
installs the Ruleset with the image-updater bypass instead of classic branch
protection, which would reject the updater's write-back push (GH006).
