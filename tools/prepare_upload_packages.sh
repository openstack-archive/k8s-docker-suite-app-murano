refresh_existing_packages=true
script_dir="$(dirname $0)"
destination_dir="$(pwd)/murano-apps"

echo "Preparing to zip archives ..."

if [[ ! -d "$destination_dir" ]]; then
    mkdir $destination_dir
fi

packages_dirs="Applications Kubernetes DockerInterfacesLibrary DockerStandaloneHost"

pushd "$script_dir/../"
for folder in $packages_dirs; do
    if [[ ! -d "$folder" ]]; then
        echo "Folder '$folder' doen't exist, skipping this step"
        continue
    fi
    echo "Zipping $folder ..."

    pushd "$folder"
        for d in $(find . -iname 'manifest.yaml' | xargs -n1 dirname); do
            path="$d"
            # get FQN for creating package
            package_name="$(grep FullName "$path/manifest.yaml" | awk '{print $2}')"
            filename="$destination_dir/$package_name.zip"
            #TODO: prepare murano packages using 'murano package-create' cmd when bugs
            # https://bugs.launchpad.net/python-muranoclient/+bug/1620981 and
            # https://bugs.launchpad.net/python-muranoclient/+bug/1620984 are fixed
            pushd "$path"
                # check that file exist and remove it or create new version
                if [ -f "$filename" ] ; then
                    if ! $refresh_existing_packages ; then
                        rm "$filename"
                    fi
                fi
                zip -r "$filename" ./*
            popd
        done
    popd
done
popd

echo "Uploading packages to Murano ..."

INITIAL_MURANO_REPO_URL=$MURANO_REPO_URL
export MURANO_REPO_URL="mock.com"

pushd "$destination_dir"
    for package in $(ls); do
        echo "Uploading $package"
        murano package-import --exists-action u $destination_dir/$package
    done
popd

echo "Cleaning up..."

export MURANO_REPO_URL=$INITIAL_MURANO_REPO_URL
rm -rf $destination_dir
