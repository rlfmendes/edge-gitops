# AutoGitOps Testing Repo

![License](https://img.shields.io/badge/license-MIT-green.svg)

> We use multiple GitHub Repos, so you have to use a PAT

- Create a Personal Access Token (PAT) in your GitHub account
  - Grant repo and package access
  - You can use an existing PAT
  - <https://github.com/settings/tokens>

- Grant SSO access to the token
  - cse-labs
  - retaildevcrews
  - Any other tenant you choose

- Create a personal Codespace secret
  - <https://github.com/settings/codespaces>
  - Name: PAT
  - Value: the PAT you just created
  - Grant access to this repo and any other repos you want

## Create a Codespace

- Click on `Code` then click `New Codespace`

Once Codespaces is running:

> Make sure your terminal is running zsh - bash is not supported and will not work

## Test Fleet

- Request the Platform Team to create your test fleet
- They will provide the branch name
- Checkout your branch

  ```bash

  cd /workspaces/edge-gitops
  git pull
  git checkout yourBranchName
  git pull

  ```

## Check your Fleet

> flt is the fleet CLI provided by the platform team

```bash

# list clusters in the fleet
flt list

# check heartbeat on the fleet
# you should get 17 bytes from each cluster
# if not, please reach out to the platform team for support
flt check heartbeat

# update the fleet
# (run twice if there are updates so you can see it's clean)
flt pull

```

> Note that the create, delete, and groups commands will not work unless you have been granted additional access

## Deploy a new app

- AI Order Accuracy is the reference app that has been renamed

```bash

cd apps/ai-order-accuracy

# check deploy targets (should be [])
flt targets list

# add the central region as a target
flt targets add central

# deploy the changes
flt targets deploy

```

## Check that your GitHub Action is running

- <https://github.com/retaildevcrews/edge-gitops/actions>
  - your action should be queued or in-progress

## Action not running

- If your action is not running within 10-15 seconds
- Verify that your PAT has sufficient permissions

  ```bash

  # try pushing manually
  git push

  ```

- Make sure your PAT has the correct permissions and is authorized for SSO in the orgs

## Check deployment

- Once the action completes successfully

```bash

# force flux to sync
flt sync

# check that ai-order-accuracy is deployed to central
flt check ai-order-accuracy

```

## Create and deploy a new app

- Early version - still brittle - follow the instructions exactly and it "should" work

```bash

# start in the apps directory
cd /workspaces/edge-gitops/apps

# make sure git is up to date
git pull

# create a new dotnet WebAPI app
# you can use any app name as long as it is PascalCaseAlpha
# if you use a different app name, you will have to make the docker image public (bug)
# you have to be an owner of github/retaildevcrews to do this
#   or change ci-cd / autogitops.json to point to a ghcr that you control
# if any of that is confusing, use TestApp
flt new dotnet webapi TestApp

# change to the testapp directory
cd testapp

# set the target to west region
flt targets clear
flt targets add west

# run GitOps manually so we don't have to add testapp to the repo
# normally, "apps" would be in separate repos - this is just a convenient test method
# you can add + commit testapp to github and run:
#   flt targets deploy
cd ../..
docker run --rm -v $(pwd):/ago ghcr.io/bartr/autogitops:beta --no-push

# push GitOps changes to git
# we don't add apps/testapp
git add deploy
git commit -m "Secure Build: testapp"
git push
cd $OLD_PWD

# check for the new namespace
flt sync
flt exec "k get ns" | grep testapp

# undeploy testapp
git pull
flt targets clear
cd ../..
docker run --rm -v $(pwd):/ago ghcr.io/bartr/autogitops:beta --no-push
git commit -am "Secure Build: testapp"
git push
cd $OLD_PWD

# force flux to sync
flt sync

# it will take a few seconds for the ns to be deleted
flt exec "k get ns" | grep testapp

# inner-loop

#### start in apps/testapp dir

# use the custom CLI
export PATH=$PWD/bin:$PATH

# build test app
kic app build

# rebuild cluster and deploy testapp + webv
kic cluster rebuild

# wait for pods to start
kic pods

# check pods
kic check all

# run tests
kic test integration
kic test load

# remove test app
cd ../..
rm -rf apps/testapp
git pull

# your repo should be "clean"

```

### Engineering Docs

- Team Working [Agreement](.github/WorkingAgreement.md)
- Team [Engineering Practices](.github/EngineeringPractices.md)
- CSE Engineering Fundamentals [Playbook](https://github.com/Microsoft/code-with-engineering-playbook)

## How to file issues and get help

This project uses GitHub Issues to track bugs and feature requests. Please search the existing issues before filing new issues to avoid duplicates. For new issues, file your bug or feature request as a new issue.

For help and questions about using this project, please open a GitHub issue.

## Contributing

This project welcomes contributions and suggestions.  Most contributions require you to agree to a Contributor License Agreement (CLA) declaring that you have the right to, and actually do, grant us the rights to use your contribution. For details, visit <https://cla.opensource.microsoft.com>

When you submit a pull request, a CLA bot will automatically determine whether you need to provide a CLA and decorate the PR appropriately (e.g., status check, comment). Simply follow the instructions provided by the bot. You will only need to do this once across all repos using our CLA.

This project has adopted the [Microsoft Open Source Code of Conduct](https://opensource.microsoft.com/codeofconduct/). For more information see the [Code of Conduct FAQ](https://opensource.microsoft.com/codeofconduct/faq/) or contact [opencode@microsoft.com](mailto:opencode@microsoft.com) with any additional questions or comments.

## Trademarks

This project may contain trademarks or logos for projects, products, or services.

Authorized use of Microsoft trademarks or logos is subject to and must follow [Microsoft's Trademark & Brand Guidelines](https://www.microsoft.com/en-us/legal/intellectualproperty/trademarks/usage/general).

Use of Microsoft trademarks or logos in modified versions of this project must not cause confusion or imply Microsoft sponsorship.

Any use of third-party trademarks or logos are subject to those third-party's policies.
