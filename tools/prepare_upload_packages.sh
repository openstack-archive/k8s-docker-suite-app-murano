refresh_existing_packages=false
destination_dir="$(pwd)/murano-apps"

echo "Preparing to zip archives ..."

if [[ ! -d "$destination_dir" ]]; then
    mkdir $destination_dir
fi

packages="Applications Kubernetes DockerInterfacesLibrary DockerStandaloneHost"

for folder in $packages; do
    if [[ ! -d "$folder" ]]; then
        echo "Folder '$folder' doen't exist, skipping this step"
        continue
    fi
    echo "Zipping $folder ..."

    pushd "$folder"
        for d in $(ls -d */); do
            if [ "$d" == "elements/" ] ; then
               continue
            else
                path="$d/package"
                if [ "$d" == "package/" ] ; then
                    path="package"
                fi
                # get FQN for creating package
                package_name="$(grep FullName "$path/manifest.yaml" | awk '{print $2}')"
                filename="$destination_dir/$package_name.zip"
                pushd "$path"
                    # check that file exist and remove it or create new version
                    if [ -f "$filename" ] ; then
                        if ! $refresh_existing_packages ; then
                            rm "$filename"
                        fi
                    fi
                    zip -r "$filename" ./*
                popd
            fi
        done
    popd
done

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
