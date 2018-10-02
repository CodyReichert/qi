<head>
<!-- 2016-12-10 Sat 14:30 -->
<meta http-equiv="Content-Type" content="text/html;charset=utf-8" />
<meta name="viewport" content="width=device-width, initial-scale=1" />
<meta name="generator" content="Org mode" />
<script type="text/javascript">
/*
@licstart  The following is the entire license notice for the
JavaScript code in this tag.
Copyright (C) 2012-2013 Free Software Foundation, Inc.
The JavaScript code in this tag is free software: you can
redistribute it and/or modify it under the terms of the GNU
General Public License (GNU GPL) as published by the Free Software
Foundation, either version 3 of the License, or (at your option)
any later version.  The code is distributed WITHOUT ANY WARRANTY;
without even the implied warranty of MERCHANTABILITY or FITNESS
FOR A PARTICULAR PURPOSE.  See the GNU GPL for more details.
As additional permission under GNU GPL version 3 section 7, you
may distribute non-source (e.g., minimized or compacted) forms of
that code without the copy of the GNU GPL normally required by
section 4, provided you include this license notice and a URL
through which recipients can access the Corresponding Source.
@licend  The above is the entire license notice
for the JavaScript code in this tag.
*/
<!--/*--><![CDATA[/*><!--*/
 function CodeHighlightOn(elem, id)
 {
   var target = document.getElementById(id);
   if(null != target) {
     elem.cacheClassElem = elem.className;
     elem.cacheClassTarget = target.className;
     target.className = "code-highlighted";
     elem.className   = "code-highlighted";
   }
 }
 function CodeHighlightOff(elem, id)
 {
   var target = document.getElementById(id);
   if(elem.cacheClassElem)
     elem.className = elem.cacheClassElem;
   if(elem.cacheClassTarget)
     target.className = elem.cacheClassTarget;
 }
/*]]>*///-->
</script>
</head>
<body>
<div id="content">
<div id="table-of-contents">
<h2>Table of Contents</h2>
<div id="text-table-of-contents">
<ul>
<li><a href="#orgc8e092b">1. Qi - Package Manager for Common Lisp</a>
<ul>
<li><a href="#orgfb3c88e">1.1. Dependencies</a></li>
<li><a href="#org35a189b">1.2. Installation</a></li>
<li><a href="#org1000872">1.3. Usage</a>
<ul>
<li><a href="#org3f6919f">1.3.1. Using Qi for a project</a></li>
<li><a href="#org9442682">1.3.2. Using Qi for global packages</a></li>
</ul>
</li>
<li><a href="#orgfff6f08">1.4. API</a>
<ul>
<li><a href="#org69fba2f">1.4.1. Hello</a></li>
<li><a href="#org0218649">1.4.2. Install</a></li>
<li><a href="#orgb47c17f">1.4.3. Install Global</a></li>
<li><a href="#orgf7083fc">1.4.4. Up</a></li>
<li><a href="#org6b044a9">1.4.5. Coming Soon</a></li>
</ul>
</li>
<li><a href="#org448aecf">1.5. Manifest</a>
<ul>
<li><a href="#orge4c1d2e">1.5.1. Adding a package to the Qi Manifest</a></li>
</ul>
</li>
<li><a href="#org044ce2a">1.6. CLI</a></li>
<li><a href="#org0b70769">1.7. Contributing</a></li>
<li><a href="#org7f76ef1">1.8. Contributors</a></li>
<li><a href="#orgb6d4971">1.9. Copyright</a></li>
<li><a href="#orge2aec5f">1.10. License</a></li>
</ul>
</li>
</ul>
</div>
</div>
<div id="outline-container-orgc8e092b" class="outline-2">
<h2 id="orgc8e092b"><span class="section-number-2">1</span> Qi - Package Manager for Common Lisp</h2>
<div class="outline-text-2" id="text-1">
<p>
Qi is a package manager for Common Lisp. There are several goals, at
the top of which are: pinned dependency versions, project local
dependencies, a place where anyone can upload their library for others
to use. A CLI, project scaffolding, and bringing the wonderful world
of Common Lisp libraries to anyone with one command are the more
long-term goals.
</p>

<p>
<b>The State of Qi</b>
</p>

<p>
Qi is a new project. There are still bugs. There are still missing
features. It might not work sometimes. It has not been tested on
multiple Lisp implementations (only SBCL). Pull-requests, issues,
feedback are appreciated.
</p>


<p>
View the HTML version of this documentation <a href="http://codyreichert.github.io/qi/">here</a>.
</p>
</div>


<div id="outline-container-orgfb3c88e" class="outline-3">
<h3 id="orgfb3c88e"><span class="section-number-3">1.1</span> Dependencies</h3>
<div class="outline-text-3" id="text-1-1">
<ul class="org-ul">
<li><a href="http://pyyaml.org/wiki/LibYAML">libyaml</a></li>
<li><a href="https://www.openssl.org">OpenSSL</a></li>
</ul>

<p>
Qi has a few Common Lisp dependencies, but they are all bundled with
the repository to allow Qi to bootstrap itself (see <code>qi/dependencies</code>
for a full list).
</p>
</div>
</div>


<div id="outline-container-org35a189b" class="outline-3">
<h3 id="org35a189b"><span class="section-number-3">1.2</span> Installation</h3>
<div class="outline-text-3" id="text-1-2">
<ol class="org-ol">
<li>Clone Qi anywhere:</li>
</ol>

<div class="org-src-container">
<pre class="src src-sh">git clone https://github.com/CodyReichert/qi.git
</pre>
</div>

<ol class="org-ol">
<li>Load Qi when SBCL starts by adding these lines to your <code>.sbclrc</code>:</li>
</ol>

<div class="org-src-container">
<pre class="src src-lisp">(load <span style="color: #00ffff;">"path/to/qi"</span>)
</pre>
</div>

<p>
To test if Qi is installed correctly, run the following the a REPL:
</p>
<div class="org-src-container">
<pre class="src src-lisp">CL-USER&gt; (qi:hello)
</pre>
</div>

<p>
<i>Notes:</i>
</p>
<ul class="org-ul">
<li>See <a href="https://github.com/CodyReichert/qi/blob/master/docs/TODO.org">docs/TODO.org</a> and <code>bin/</code> for some work that can/should be done
around this part.</li>
</ul>
</div>
</div>

<div id="outline-container-org1000872" class="outline-3">
<h3 id="org1000872"><span class="section-number-3">1.3</span> Usage</h3>
<div class="outline-text-3" id="text-1-3">
</div><div id="outline-container-org3f6919f" class="outline-4">
<h4 id="org3f6919f"><span class="section-number-4">1.3.1</span> Using Qi for a project</h4>
<div class="outline-text-4" id="text-1-3-1">
<p>
This section covers using Qi for a single project.
</p>

<p>
The only requirement to installing a systems dependencies with Qi,
is a <code>qi.yaml</code>.
</p>

<p>
The <code>qi.yaml</code> specifies a projects dependencies. For an example of
what this looks like, checkout out <a href="https://github.com/codyreichert/qi">Qi's qi.yaml</a>.
</p>

<p>
Two required pieces to the <code>qi.yaml</code> are <i>name</i> and <i>packages</i>. So
a basic project would look like this:
</p>

<div class="org-src-container">
<pre class="src src-yaml"><span style="color: #0000ff;">name</span>: my-project
<span style="color: #0000ff;">packages</span>:
  - <span style="color: #0000ff;">name</span>: alexandria
  - <span style="color: #0000ff;">name</span>: clack
    <span style="color: #0000ff;">url</span>: https://github.com/fukamachi/clack/archive/master.tar.gz
  - <span style="color: #0000ff;">name</span>: cl-pass
    <span style="color: #0000ff;">url</span>: https://github.com/eudoxia0/cl-pass.git
</pre>
</div>

<p>
Above there are three types of packages: Manifest, tarball, and git.
</p>

<ul class="org-ul">
<li><b>Manifest</b>: "Known" packages from the <a href="https://github.com/CodyReichert/qi/blob/master/manifest/manifest.lisp">Qi manifest</a>.</li>
<li><b>Tarball</b>: An HTTP URL to tarball.</li>
<li><b>Git</b>: A git repository. You can also specify a tag or hash.</li>
<li><b>Mercurial</b>: A link to a mercurial repository.</li>
<li><b>Local</b>: TODO, but you will be able to put a local path.</li>
</ul>

<p>
With the above qi.yaml in your project, you can run the following
to install and load the systems:
</p>

<div class="org-src-container">
<pre class="src src-lisp">* (load <span style="color: #00ffff;">"myproject.asd"</span>)
* (qi:install <span style="color: #00ff00;">:myproject</span>)
</pre>
</div>

<p>
You can also install project dependencies from the command-line:
</p>

<div class="org-src-container">
<pre class="src src-sh">qi --install-deps path/to/myproject.asd
</pre>
</div>

<p>
Qi take's care of any transitive dependencies and will let you know
of any that it could <i>not</i> install. In a case where Qi can not
install some dependencies, add direct links to those packages in
your <code>qi.yaml</code>.
</p>
</div>
</div>

<div id="outline-container-org9442682" class="outline-4">
<h4 id="org9442682"><span class="section-number-4">1.3.2</span> Using Qi for global packages</h4>
<div class="outline-text-4" id="text-1-3-2">
<p>
You can also manage global packages with Qi. This is useful for
downloading and install packages that you want to always have
available. There's a simple interface, and two commands are the
most useful:
</p>

<p>
<b>install-global</b>
</p>

<div class="org-src-container">
<pre class="src src-lisp">* (qi:install-global <span style="color: #00ff00;">:cl-project</span>)
</pre>
</div>

<p>
Running <code>install-global</code> installs the package into the global
package directory (qi/dependencies). The installed package is made
available in the current session.
</p>

<p>
<b>up</b>
</p>

<div class="org-src-container">
<pre class="src src-lisp">* (qi:up <span style="color: #00ff00;">:cl-project</span>)
</pre>
</div>

<p>
Running <code>up</code> loads a package that's in your global package
directory and makes it available in the current session.
</p>
</div>
</div>
</div>


<div id="outline-container-orgfff6f08" class="outline-3">
<h3 id="orgfff6f08"><span class="section-number-3">1.4</span> API</h3>
<div class="outline-text-3" id="text-1-4">
<p>
Qi's API is composed of a few commands, documented below:
</p>
</div>

<div id="outline-container-org69fba2f" class="outline-4">
<h4 id="org69fba2f"><span class="section-number-4">1.4.1</span> Hello</h4>
<div class="outline-text-4" id="text-1-4-1">
<p>
Prints some information about Qi to <b>standard-output</b>. If this
prints, Qi is installed correctly.
</p>

<div class="org-src-container">
<pre class="src src-lisp">(qi:hello)
</pre>
</div>
</div>
</div>

<div id="outline-container-org0218649" class="outline-4">
<h4 id="org0218649"><span class="section-number-4">1.4.2</span> Install</h4>
<div class="outline-text-4" id="text-1-4-2">
<p>
Installs a system and it's dependencies. All dependencies are
installed local to the system directory in <code>.dependencies/</code>.
</p>

<ul class="org-ul">
<li>For any dependencies that are not already available, Qi will try to
download them from the Manifest. If all else fails, it will print
to <b>standard-output</b> what packages could not be installed.</li>
</ul>

<div class="org-src-container">
<pre class="src src-lisp">(qi:install <span style="color: #00ff00;">:system</span>)
</pre>
</div>
</div>
</div>

<div id="outline-container-orgb47c17f" class="outline-4">
<h4 id="orgb47c17f"><span class="section-number-4">1.4.3</span> Install Global</h4>
<div class="outline-text-4" id="text-1-4-3">
<p>
Installs a system to the global package directory. The system
should be from the Manifest. The system is made available in the
current session.
</p>

<div class="org-src-container">
<pre class="src src-lisp">(qi:install-global <span style="color: #00ff00;">:system</span> <span style="color: #ffff00;">&amp;optional</span> version)
</pre>
</div>

<p>
<i>To make a global system available at any time, you can use</i>
<i>(qi:up :system)</i>
</p>
</div>
</div>

<div id="outline-container-orgf7083fc" class="outline-4">
<h4 id="orgf7083fc"><span class="section-number-4">1.4.4</span> Up</h4>
<div class="outline-text-4" id="text-1-4-4">
<p>
ASDF load's a system to be available in the current session.
</p>

<div class="org-src-container">
<pre class="src src-lisp">(qi:up <span style="color: #00ff00;">:system</span>)
</pre>
</div>

<p>
<i>This is the equivalent of running (asdf:load-system :system)</i>
</p>
</div>
</div>

<div id="outline-container-org6b044a9" class="outline-4">
<h4 id="org6b044a9"><span class="section-number-4">1.4.5</span> Coming Soon</h4>
<div class="outline-text-4" id="text-1-4-5">
<p>
<b>Not implemented</b> <code>(qi:new ...)</code>
</p>

<p>
Generate a new project scaffold.
</p>

<p>
<b>Not implemented</b> <code>(qi:setup ...)</code>
</p>

<p>
Generate a qi.yaml for an existing project.
</p>

<p>
<b>Not implemented</b> <code>(qi:update-manifest ...)</code>
</p>

<p>
Update the Qi manifest to get access to new packages and updates.
</p>

<p>
<b>Not implemented</b> <code>(qi:publish ...)</code>
</p>

<p>
Publish a new package to the Qi Manifest
</p>
</div>
</div>
</div>


<div id="outline-container-org448aecf" class="outline-3">
<h3 id="org448aecf"><span class="section-number-3">1.5</span> Manifest</h3>
<div class="outline-text-3" id="text-1-5">
<p>
The <a href="https://github.com/CodyReichert/qi/blob/master/manifest/manifest.lisp">Qi Manifest</a> is a list of known packages - which makes it easy
to simply install packages by their name. Qi's Manifest was
initially seeded by <a href="https://github.com/quicklisp/quicklisp-projects/">Quicklisp's projects</a> which means that any
project you can find in Quicklisp can be found in Qi.
</p>
</div>

<div id="outline-container-orge4c1d2e" class="outline-4">
<h4 id="orge4c1d2e"><span class="section-number-4">1.5.1</span> Adding a package to the Qi Manifest</h4>
<div class="outline-text-4" id="text-1-5-1">
<p>
Any and all packages are welcome in the Qi Manifest. The only
requirement is that it is a lisp project that is asdf-loadable.
</p>

<p>
To add a package to the manifest, submit a pull-request at
<a href="https://github.com/CodyReichert/qi/">https://github.com/CodyReichert/qi/</a>, or send a patch file to
codyreichert@gmail.com.
</p>

<p>
See <a href="https://github.com/CodyReichert/qi/blob/master/docs/TODO.org">docs/TODO.org</a> for some work to be done in this
area. Ideally, we have <code>recipes/</code> that contains the information
about each Qi package. That way a new recipe can be added and the
Manifest can be updated.
</p>
</div>
</div>
</div>


<div id="outline-container-org044ce2a" class="outline-3">
<h3 id="org044ce2a"><span class="section-number-3">1.6</span> CLI</h3>
<div class="outline-text-3" id="text-1-6">
<p>
The Qi CLI provides a few basic commands (more coming soon!). Make
sure that <code>qi/bin/</code> is in your path, or move <code>qi/bin/qi</code> into your
path.
</p>

<p>
Run <code>$ qi --help</code> For info on the available commands:
</p>

<div class="org-src-container">
<pre class="src src-sh">&#955; qi -h
Qi - A simple, open, free package manager for Common Lisp.

Usage: qi [-h|--help] [-u|--upgrade] [-i|--install PACKAGE] [-d|--install-deps ASD-FILE] [Free-Args]

Available options:
  -h, --help                   Print this help menu.
  -u, --upgrade                Upgrade Qi (pull the latest from git)
  -i, --install PACKAGE        Install a package from Qi (global by default)
  -d, --install-deps ASD-FILE  Install dependencies locally for the specified system

Issues https://github.com/CodyReichert/qi
</pre>
</div>
</div>
</div>


<div id="outline-container-org0b70769" class="outline-3">
<h3 id="org0b70769"><span class="section-number-3">1.7</span> Contributing</h3>
<div class="outline-text-3" id="text-1-7">
<p>
PRs and Issues are extremely welcomed and will likely all be
merged or addressed. See the <a href="https://github.com/CodyReichert/qi/blob/master/docs/TODO.org">docs/TODO.org</a> for a list of tasks
that I'd like to see done. Make a PR or start a conversation if
there's anything you'd like to see.
</p>

<p>
With any PR - add your name to the <code>Contributors</code> section below.
</p>
</div>
</div>


<div id="outline-container-org7f76ef1" class="outline-3">
<h3 id="org7f76ef1"><span class="section-number-3">1.8</span> Contributors</h3>
<div class="outline-text-3" id="text-1-8">
<ul class="org-ul">
<li>Cody Reichert (codyreichert@gmail.com)</li>
<li>Nicolas Lamirault (@nlamirault)</li>
<li>Alex Dunn (@dunn)</li>
</ul>
</div>
</div>


<div id="outline-container-orgb6d4971" class="outline-3">
<h3 id="orgb6d4971"><span class="section-number-3">1.9</span> Copyright</h3>
<div class="outline-text-3" id="text-1-9">
<p>
Copyright (c) 2015 Cody Reichert (codyreichert@gmail.com)
</p>
</div>
</div>


<div id="outline-container-orge2aec5f" class="outline-3">
<h3 id="orge2aec5f"><span class="section-number-3">1.10</span> License</h3>
<div class="outline-text-3" id="text-1-10">
<p>
BSD
</p>
</div>
</div>
</div>
</div>
<div id="postamble" class="status">
<p class="date">Created: 2016-12-10 Sat 14:30</p>
<p class="validation"><a href="http://validator.w3.org/check?uri=referer">Validate</a></p>
</div>
</body>
</html>