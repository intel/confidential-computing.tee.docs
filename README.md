# Confidential Computing Documentation

In this repository, you can find sources for Confidential Computing-related documentation.
The parsed version of this documentation is reachable at [https://cc-enabling.trustedservices.intel.com/](https://cc-enabling.trustedservices.intel.com/).

In the following, we explore details about contributing to our documentation.


## 1. Who can contribute?

Anyone who wants to extend and improve our documentation can contribute.

> ***Important:*** Every contributor has to agree to the license of this repository.
More details are described in our [Contributing](CONTRIBUTING.md) document.


## 2. How to contribute?

Depending on your goal, there are different recommended ways to contribute to the documentation and we describe them in the following subsections:

- [Minor Changes](#21-minor-changes)
- [Major Changes](#22-major-changes)
- [Questions and Remarks](#23-questions-and-remarks)


### 2.1 Minor Changes

For minor changes, e.g., updating a broken link, fixing typos, or updating a command, it is not necessary to download and install any tools.
All you need is a GitHub account, which you can create at [github.com/signup](https://github.com/signup).

Process for minor changes:

- Navigate to the page on [our documentation website](https://cc-enabling.trustedservices.intel.com/) that you want to edit.
- Click the "Edit this page" icon at the top right of the page.
    This will bring you to the source of the page at GitHub.
- If not already done, login to your GitHub account.
- On the GitHub page showing you the source of the page you want to edit, click the pencil icon above the editor.
- If you have never before made any modifications to this repository, GitHub will ask you to generate a fork of the repository.
    Please create a fork by clicking the "Fork this repository" button.
    - In short, a fork is your own copy of a repository.
    This copy is needed because you are not allowed to directly do changes to our documentation repository.
- Use the web editor to perform the desired changes.
- Once you are done with your changes, click on the "Commit changes..." button above the text editor.
- In the upcoming popup, fill out the two input fields.
    - For the "commit message" include a brief summary of the changes.
    - For the "extended description", add an extended description of your changes, add a blank line, and add a sign off line.
        Ideally, the extended description allows the reviewer to understand your changes without looking at the code.
        More details about the sign off line can be found in our [Contributing](CONTRIBUTING.md) document.
        Please note that we cannot accept any external commit without such a sign off.
- At this point, you have created a "commit" containing your changes inside your fork of the documentation.
    The last step is to make your changes known to the main documentation repository.
    You can do this by clicking "Create pull request" on the "Comparing changes" page, which brings you to a page with the title "Open a pull request".
- Give your pull request a title, add a description, and click "Create pull request", which will open a pull request.
- After the pull request is received, the documentation team will review your pull request.
    Potentially, you will receive requests for changes.


### 2.2 Major Changes

For major changes, e.g., change major portions of a page, add a new page, or test something locally, we recommend working on your local machine first and bring the changes back to this repository afterwards.
In the following subsection, we describe a recommended way to contribute major changes:

- [Prerequisites](#221-prerequisites)
- [Setup remote and local repository](#222-setup-remote-and-local-repository)
- [Start and use local documentation server](#223-start-and-use-local-documentation-server)
- [Build documentation](#224-build-documentation)
- [Edit documentation locally](#225-edit-documentation-locally)
- [Push changes to your remote repository](#226-push-changes-to-your-remote-repository)
- [Bring changes to this repository](#227-bring-changes-to-this-repository)


#### 2.2.1 Prerequisites

- Install Git ([guide](https://git-scm.com/downloads))
- Setup GitHub account ([github.com/signup](https://github.com/signup)).
- [Optional] Install Visual Studio Code ([guide](https://code.visualstudio.com/))
- [Optional] Install Docker ([guide](https://docs.docker.com/engine/install/))


#### 2.2.2 Setup remote and local Repository

Process:

1. If not done before, create a fork of this repository:

    - On the overview page of this repository at GitHub, you can generate a fork by clicking the "Fork" button on the upper-right corner.
        This opens a page with the title "Create a new fork".
    - On the "Create a new fork" page, make sure you are the owner of the fork, optionally change the repository name, optionally change the description, and click the "Create fork" button.

    In short, a fork is your own copy of a repository.
    This copy is needed because you are not allowed to directly do changes to our repository.

2. Create a local clone of your fork of this repository.

    - Go to the GitHub page of the fork created in step 1.
    - Click the "Code" button above the file overview, click on "HTTPS", and copy the URL shown in the text field.
        In the following, we refer to the copied URL as `<fork url>`.
    - Create a folder on your machine, which should contain the files belonging to your fork of this repository.
    - Use your favorite terminal to navigate to the folder you just created.
    - In your favorite terminal, execute the following to create a local clone of your fork: `git clone <fork url>`.


#### 2.2.3 Start and Use Local Documentation Server

To conveniently see a live preview of your changes, we recommend starting a documentation server locally.
This section explains how to serve the entire documentation and how to serve child documentations directly.

Process:

- With your favorite terminal, navigate to the folder containing the local clone of your fork (see step 2 of Section 2.2.2).
- If not done before, build the Dockerfile used to create the documentation:

    ``` {.bash}
    docker build -t intel/cc-docu -f build/Dockerfile build
    ```

- Serve the entire documentation (parent + all children):
    - Start Docker-based preview using the parent config:

        ``` {.bash}
        docker run --rm -i \
        --env LOCAL_DEPLOYMENT=true \
        -p 8000:8000 \
        --name cc-docu \
        -v "${PWD}":/repo \
        intel/cc-docu \
        -f /repo/docs/parent_doc/mkdocs.yml
        ```

    - Open the preview of the entire documentation at [http://localhost:8000/](http://localhost:8000/).
    - Whenever a file is changed for the parent or a child documentation, the related documentation is rebuild automatically and the browser is refreshed.

- Serve one child documentation:
    - Start Docker-based preview using the configuration of this child, e.g.:

        ``` {.bash}
        docker run --rm -i \
        --env LOCAL_DEPLOYMENT=true \
        -p 8001:8000 \
        --name cc-docu-child \
        -v "${PWD}":/repo \
        intel/cc-docu \
        -f /repo/docs/child_docs/intel-tdx-enabling-guide/mkdocs.yml
        ```

    - Open the preview of the child documentation at [http://localhost:8001/](http://localhost:8001/).
    - Whenever a file is changed for the child documentation, the documentation is rebuild automatically and the browser is refreshed.


#### 2.2.4 Build Documentation

The recommended way to verify publication output is to build through the configuration of the parent documentation at `docs/parent_doc/mkdocs.yml`.
This section also explains how to build child documentation directly for faster local checks.

The parent documentation content lives under `docs/parent_doc/docs/`.
The parent configuration lives under `docs/parent_doc/mkdocs.yml`.
The shared base configuration for parent and child builds remains at `docs/mkdocs_base.yml`.
Child documentations keep `includes`, `docs/assets`, `docs/misc`, `docs/overrides`, and `docs/stylesheets` as symlinks to shared parent content.

Process:

- With your favorite terminal, navigate to the folder containing the local clone of your fork (see step 2 of Section 2.2.2).
- If not done before, build the Dockerfile used to create the documentation:

    ``` {.bash}
    docker build -t intel/cc-docu -f build/Dockerfile build
    ```

- Build the entire documentation via Docker (recommended default):

    ``` {.bash}
    docker run --rm -i \
    --env LOCAL_DEPLOYMENT=true \
    -v "${PWD}":/repo \
    --entrypoint mkdocs \
    intel/cc-docu \
    build -f /repo/docs/parent_doc/mkdocs.yml
    ```

- Build one child documentation via Docker, e.g.:

    ``` {.bash}
    docker run --rm -i \
    --env LOCAL_DEPLOYMENT=true \
    -v "${PWD}":/repo \
    --entrypoint mkdocs \
    intel/cc-docu \
    build -f /repo/docs/child_docs/intel-tdx-enabling-guide/mkdocs.yml
    ```

The rendered parent output is written to `docs/parent_doc/site/`, matching what we publish at [https://cc-enabling.trustedservices.intel.com/](https://cc-enabling.trustedservices.intel.com/).
The rendered child output is written to `docs/child_docs/<child dir>/site/`.


#### 2.2.5 Edit Documentation Locally

To change the documentation, we recommend that you open the local clone of your fork with an IDE.
In the following, we assume you are using [Visual Studio Code (VSCode)](https://code.visualstudio.com/) as this IDE brings some convenience features that improve the documentation modification experience.

##### Open documentation folder

- Open repository in VSCode. Two possible ways:
    - Open repository via terminal:
        - Use your favorite terminal to navigate to folder to which you cloned your fork in step 2 of Section 2.2.2.
        - Execute `code .`.
    - Open repository using UI:
        - Click on "File" on the top left corner of VSCode.
        - Click on "Open Folder..." in the menu that opens.
        - Select the folder to which you cloned your fork in step 2 of Section 2.2.2.
- If not installed before, VSCode will propose to install recommended extensions.
  For the most convenient editing experience, we recommend installing the extensions, but they are not strictly necessary.

###### Find source Markdown file of documentation page

- To edit a specific documentation page, find the source [Markdown](https://daringfireball.net/projects/markdown/) file for the page in the `docs` folder inside your local fork clone, and open the file.
    - If you do not know the location of the source Markdown file, navigate to the page you want to edit on [https://cc-enabling.trustedservices.intel.com/](https://cc-enabling.trustedservices.intel.com/).
        Click on the **Edit** Icon on the upper right corner of the documentation page you want to edit.
        This will bring you a GitHub page with a URL looking like `https://github.com/.../edit/.../docs/[path]`.
        The file you want to edit is located in your local clone at `docs/[path]`.


##### Edit Markdown file of documentation page

- Just edit the source files of the documentation adhering to the Markdown syntax.
    - If you are new to Markdown, you should first learn the basics.
        Using your favorite search engine, you will find multiple guides searching for "markdown guide".
        Don't worry, the basics are very easy to learn.
    - If you know the Markdown basics (or have just learned it), you might be interested to learn about and use the [advanced features offered by our documentation](https://squidfunk.github.io/mkdocs-material/reference/).
        Alternatively, you can browse through the [documentation pages provides online]((https://cc-enabling.trustedservices.intel.com/)).
        If you like what you see on a page, just click on the "View source of this this page" icon present on the top of every page.
        This will bring you to the source file of the documentation pages from where you can copy the desired Markdown feature.
- If you are using a local documentation server as described in [Section 2.2.3](#223-start-and-use-local-documentation-server), the website will automatically reload on every save of a Markdown file.


#### 2.2.6 Push Changes to your Remote Repository

For the following instructions, we assume you know how to use git with your IDE or with your favorite terminal.
For VSCode's source control feature, you can find a lot of information in the [corresponding guide](https://code.visualstudio.com/docs/sourcecontrol/overview#_commit).

Process:

- Create a new branch inside your fork with a name helping you to recognize the change.
- Create one commit for each cohesive change you did to the documentation.
    For each commit, please use the following format for your commit message:

    - In the first line, include a brief summary of the changes.
    - After one blank link, add an extended description of your changes.
        Ideally, this description allows the reviewer to understand your changes without looking at the code.
    - After one blank line, sign off your commit.
        More details can be found in our [Contributing](CONTRIBUTING.md) document.
        Please note that we cannot accept any external commit without a sign off.
- Push your branch to your fork at GitHub.


#### 2.2.7 Bring Changes to this Repository

At this point, your changes are contained in your fork of the documentation.
The last step is to make your changes known to this repository allowing us to see your proposed changes.

Process:

- On [github.com](https://github.com/), navigate to your fork and to the branch containing the changes you currently want to contribute.
- Create a pull request for this branch.
    You can do this, for example, by clicking on the "Contribute" button above the overview of files and then on the "Open pull request" button.
    This brings you to a page with the title "Comparing changes".
- Give your pull request a title, add a description, and click "Create pull request", which will open a pull request.
- Now, our documentation team will review your pull request.
    Potentially, you will receive requests for changes.


### 2.3 Questions and Remarks

For questions and remarks regarding the documentation, which you do not directly want to contribute as a change, please open a GitHub Issue in this repository.
