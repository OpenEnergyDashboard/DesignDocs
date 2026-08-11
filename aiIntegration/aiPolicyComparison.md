# OED AI Policy Comparison

Converted from the original three-tab workbook into a single Markdown document.
Google Sheets: https://docs.google.com/spreadsheets/d/1XF7leNgV0ftwLTxSF8yHJUb8IIJxx806YyQnTnyd3NE/edit?usp=sharing

## Comparison Table

Open Source AI Policies Compared for OED<br>Data and policy information current as of August 2026, based on publicly available information from the cited project websites and repositories.

| Project Name | Policy Link | AI Allowed<br>(source table) | Disclosure Required<br>(source table) | Copyright Stmt<br>(source table) | Human in Loop<br>(source table) | Stance | Source Notes (Source table) | Relevance to OED/ Student | Policy Relevance to OED | Contributor<br>Responsible? | Human Review<br>Required? | Comments |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| Adwaita | <https://gitlab.gnome.org/GNOME/libadwaita/-/blob/main/CONTRIBUTING.md?ref_type=heads#use-of-generative-ai> | No | - | - | - | Rejecting |  | Low | Low | N/A | N/A |  |
| Alacritty | <https://github.com/alacritty/alacritty/blob/master/CONTRIBUTING.md#llmai-contributions> | No | - | - | - | Rejecting |  | Low | Low | N/A | N/A |  |
| Apache Airflow | <https://github.com/apache/airflow/blob/main/contributing-docs/05_pull_requests.rst#gen-ai-assisted-contributions> | Yes | Yes | Yes | Yes | Cautious | Add Copilot code review instructions to catch AI-slop PRs | Low | Low | Yes | Yes |  |
| Apache CouchDB | <https://github.com/apache/couchdb/blob/main/CONTRIBUTING.md#artificial-intelligence-and-large-language-models-contributions-policy> | No | - | - | - | Rejecting |  | Low | Low | N/A | N/A |  |
| Apache DataFusion | <https://datafusion.apache.org/contributor-guide/index.html#ai-assisted-contributions> | Yes | No | No | Yes | Cautious | Better ways to contribute than an AI dump | Low | Med | Yes | Yes |  |
| Apache Kvrocks | <https://kvrocks.apache.org/community/contributing/#guidelines-for-ai-assisted-contributions> | Yes | Yes | Yes | Yes | Cautious |  | Low | Med | Yes | Yes | AI allowed, contributor accountable and must verify the output. |
| Apache PouchDB | <https://github.com/apache/pouchdb/blob/master/CONTRIBUTING.md#artificial-intelligence-and-large-language-models-contributions-policy> | No | - | - | - | Rejecting |  | Low | Low | N/A | N/A |  |
| Apache Software Foundation (ASF) | <https://www.apache.org/legal/generative-tooling.html> | Yes | Yes | Yes | - | Cautious | Applies to all ASF projects; enforcement decentralized. Requires 'Generated-by:' in commit message. | Med | High | Yes | Not explicitly stated. | Important because it gives broad open-source legal guidance on generative tooling, disclosure, and licensing. |
| Arrow | <https://arrow.apache.org/docs/dev/developers/overview.html#ai-generated-code> | Yes | Yes | Yes | Yes | Cautious |  | Low | Low | Yes | Yes | Strong model for disclosure, understanding generated code, and owning/debugging AI-assisted work. |
| Asahi Linux | <https://asahilinux.org/docs/project/policies/slop/> | No | - | - | - | Rejecting |  | Low | Low | N/A | N/A |  |
| attrs | <https://github.com/python-attrs/attrs/blob/main/.github/AI_POLICY.md> | Yes | ? | Yes | Yes | Cautious | No LLM bots in Co-authored-by:s. | Low | Low | Yes | Yes | No explicit general disclosure requirement. The policy allows LLM-assisted work only if a human owns the copyright, understands the code, and takes full responsibility. No LLM bots in Co-authored-by: and says LLM-generated summaries/review comments must be fact-checked. Shared Policy with Pip |
| CapyPDF | <https://github.com/jpakkane/capypdf/?tab=readme-ov-file#ai-policy> | No | - | - | - | Rejecting |  | Low | Low | N/A | N/A |  |
| CC Open Source | <https://opensource.creativecommons.org/contributing-code/> | No | - | - | - | Rejecting |  | Low | Low | N/A | N/A |  |
| CCExtractor | <https://ccextractor.org/public/gsoc/ai_policy/> | Yes | Yes | Yes | Yes | Cautious | Mark PRs as AI-generated/AI-assisted/No AI used | High | High | Yes | Yes | Sole Responsible Author, it has a student/GSoC context and clear PR labeling for AI-generated, AI-assisted, or no-AI work. |
| cilium | <https://github.com/cilium/community/blob/main/AI-POLICY.md> | Yes | Yes | Yes | Yes | Restrictive | DCO signoff required for all contributions including AI-generated ones. | Low | Med | Yes | Yes | Signoff required |
| Clojure | <https://clojure.org/dev/contributor_agreement#_no_generated_code> | No | - | - | - | Rejecting |  | Low | Low | N/A | N/A |  |
| CloudNativePG | <https://github.com/cloudnative-pg/governance/blob/main/AI_POLICY.md> | Yes | Yes | Yes | Yes | Cautious |  | Low | Low | Yes | Yes |  |
| conda | <https://docs.conda.io/projects/conda/en/latest/dev-guide/contributing.html#generative-ai> | Yes | No | Yes | Yes | Cautious |  | Low | Low | Yes | Yes |  |
| CPython | <https://devguide.python.org/getting-started/ai-tools/index.html> | Yes | No | No | Yes | Cautious | Disclosure of AI tools appreciated, not required. | Med | High | Yes | Yes | Strong emphasis on focused changes, existing coding patterns, tests. Disclosure is only encouraged, not required |
| CuPy | <https://docs.cupy.dev/en/stable/contribution.html#ai-policies> | Yes | No | No | Yes | Cautious |  | Low | Low | Yes | Yes | Allows AI but has less detailed policy language. Useful mainly for warning against AI spam/testbed behavior. |
| curl | <https://curl.se/dev/contribute.html#on-ai-use-in-curl> | Yes | Yes | Yes | Yes | Cautious | A contribution should be worth more to the project than the time it takes to review it. | Low | Low | Yes | Yes | AI-assisted work must be useful enough to justify review time. Very relevant for OED maintainers. |
| DataJourneyHQ | <https://github.com/DataJourneyHQ/DataJourney/wiki/Contribution-Guidelines-(AI%E2%80%90Aware)> | Yes | Yes | No | - | Cautious |  | Low | Low | Yes | Not explicitly stated. |  |
| Django | <https://docs.djangoproject.com/en/dev/internals/contributing/writing-code/submitting-patches/#ai-assisted-contributions> | Yes | Yes | No | Yes | Cautious | PR template includes AI disclosure; no automated AI reviews. | Med | Low | Yes | Yes | It requires AI disclosure, manual verification, architecture alignment, tests, docs, full checks, and bans automated AI reviews on submitted PRs. |
| dlt | <https://github.com/dlt-hub/dlt> | Yes | No | No | No | Pro | CONTRIBUTING_AI.md ('We strongly encourage using AI coding agents') is in private repo. Two-tier system: reviewed AI output = contributor's own; unreviewed = must carry explicit disclaimer. 'Code not fully reviewed by a human will never get merged.' Source: blog.probabl.ai interview with dlt CTO, May 2026. | Low | Low | Not explicitly stated. | Not explicitly stated. |  |
| do | <https://codeberg.org/cgranade/do#license-and-ai-policy> | No | - | - | - | Rejecting |  | Low | Low | N/A | N/A |  |
| Drupal | <https://www.drupal.org/docs/develop/issues/issue-procedures-and-etiquette/policy-on-the-use-of-ai-when-contributing-to-drupal> | Yes | Yes | Yes | Yes | Cautious |  | Med | High | Yes | Yes | Strong responsibility language, copyright and licensing rules, disclosure thresholds, examples of bad AI use, enforcement, and a GSoC/student-learning note. |
| Dune 3D | <https://github.com/dune3d/dune3d/blob/main/CONTRIBUTING.md#use-of-large-language-models--generative-ai> | No | - | - | - | Rejecting |  | Low | Low | N/A | N/A |  |
| EasyBuild | <https://docs.easybuild.io/policies/ai/> | Yes | Yes | No | Yes | Cautious | Requires declaration of specific AI models/tools used. | Low | Low | Not explicitly stated. | Yes |  |
| Elastic (GNOME) | <https://gitlab.gnome.org/World/elastic#use-of-generative-ai> | No | - | - | - | Rejecting |  | Low | Low | N/A | N/A |  |
| Elementary OS | <https://docs.elementary.io/contributor-guide/development/generative-ai-policy> | No | - | - | - | Rejecting |  | Low | Low | N/A | N/A |  |
| FastAPI | <https://tiangolo.com/open-source/contributing/#automated-code-and-ai> | Yes | No | No | Yes | Cautious | If human effort in PR is less than effort to review it, don't submit. | Low | Med | Yes | Yes | Do not submit AI automated PRs if the human effort is less than the review effort. |
| Firefox | <https://firefox-source-docs.mozilla.org/contributing/ai-coding.html> | Yes | No | No | Yes | Cautious |  | Med | High | Yes | Yes | It explicitly says humans remain accountable, must understand and self-review the code, must protect sensitive data, and should not use AI to bypass learning on “Good First” / “Good Next” bugs. The learning-focused language is useful for OED. |
| Flutter | <https://github.com/flutter/flutter/blob/master/docs/contributing/Tree-hygiene.md#ai-contribution-guidelines> | Yes | No | No | Yes | Cautious |  | Low | Med | Yes | Yes | Review all AI code, understand and discuss it, verify AI-generated PR text, close low-quality AI PRs, and watch for AI-generated files or mismatched descriptions. |
| Forgejo | <https://codeberg.org/forgejo/governance/src/branch/main/AIAgreement.md> | No | - | - | - | Rejecting |  | Low | Low | N/A | N/A |  |
| GDAL | <https://gdal.org/en/stable/community/ai_tool_policy.html> | Yes | Yes | Yes | Yes | Restrictive |  | Low | Med | Yes | Yes | Human must be primary author, must understand all contributions, disclosure required, contributor responsible, agents banned, enforcement/closure/ban process included. Maintainer-burden and accountability language. |
| Gedit | <https://gitlab.gnome.org/World/gedit/gedit/-/blob/master/docs/guidelines/no-llm-tools.md> | No | - | - | - | Rejecting |  | Low | Low | N/A | N/A |  |
| Gentoo Linux | <https://wiki.gentoo.org/wiki/Project:Council/AI_policy> | No | - | - | - | Rejecting |  | Low | Low | N/A | N/A |  |
| Ghostty | <https://github.com/ghostty-org/ghostty/blob/main/AI_POLICY.md> | Yes | Yes | No | Yes | Cautious | Our reason for the strict AI policy is not due to an anti-AI stance, but instead due to the number of highly unqualified people using AI. | Low | Low | Yes | Yes |  |
| GIMP | <https://gitlab.gnome.org/GNOME/gimp/-/blob/master/.gitlab/merge_request_templates/default.md?plain=1#L11-12> | No | - | - | - | Rejecting |  | Low | Low | N/A | N/A |  |
| Gitea | <https://github.com/go-gitea/gitea/blob/main/CONTRIBUTING.md#ai-contribution-policy> | Yes | Yes | No | Yes | Cautious |  | Low | Med | Yes | Yes | AI allowed with disclosure, close review, manual testing, contributors must understand/defend/revise their work, and maintainers may close low-quality or undisclosed AI-assisted work. |
| Glasgow Interface Explorer | <https://glasgow-embedded.org/latest/contribute.html#contributing-code-or-documentation> | No | - | - | - | Rejecting |  | Low | Low | N/A | N/A |  |
| GNOME Extensions | <https://gjs.guide/extensions/review-guidelines/review-guidelines.html#extensions-must-not-be-ai-generated> | Yes* | - | - | Yes | Restrictive | Extension developers should be able to justify and explain the code they submit. | Low | Med | Yes | Yes | It allows AI as learning aid/autocomplete while rejecting AI-generated submissions with signs like unnecessary code, inconsistent style, imaginary API use, and LLM-prompt comments. |
| GNOME Loupe | <https://gitlab.gnome.org/GNOME/loupe/-/blob/main/CONTRIBUTING.md?ref_type=heads#use-of-generative-ai> | No | - | - | - | Rejecting |  | Low | Low | N/A | N/A |  |
| GNU Binutils | <https://sourceware.org/binutils/wiki/LLM_Generated_Content> | No | - | - | - | Rejecting |  | Low | Low | N/A | N/A |  |
| goose | <https://github.com/block/goose/blob/main/HOWTOAI.md> | Yes | No | No | Yes | Pro | AGENTS.md file provided. | Low | Med | Yes | Yes | It has practical AI workflow guidance, testing expectations, security cautions, and “you are accountable” language. |
| GoToSocial | <https://codeberg.org/superseriousbusiness/gotosocial/src/branch/main/CODE_OF_CONDUCT.md> | No | - | - | - | Rejecting |  | Low | Low | N/A | N/A |  |
| Homebrew | <https://github.com/Homebrew/brew/blob/main/CONTRIBUTING.md#artificial-intelligencelarge-language-model-aillm-usage> | Yes | Yes | No | Yes | Cautious | Disclose model/tool; only one AI-assisted PR open at a time. | Low | Med | Yes | Yes | Only one AI-assisted PR open at a time |
| Icechunk | <https://icechunk.io/en/latest/ai-policy/> | Yes | No | No | Yes | Cautious |  | Low | High | Yes | Yes | It directly addresses maintainer burden, large AI-assisted PRs, closing impractical PRs, and domain-specific documentation errors. |
| IREE | <https://iree.dev/developers/general/contributing/#ai-tool-use> | Yes | Yes | Yes | Yes | Cautious | Use 'Assisted-by:' or 'Co-authored-by:' | Low | Med | Yes | Yes | AI-assisted PRs, issues, and design proposals must be reviewed and understood; substantial AI content should be labeled with Assisted-by or Co-authored-by; contributors are responsible for license rights and avoiding regenerated copyrighted material. |
| Jellyfin | <https://jellyfin.org/docs/general/contributing/llm-policies/> | Yes | No | No | Yes | Cautious |  | Med | Low | Yes | Yes | Useful for maintainer burden language. No raw LLM communication, no vibe coding. |
| Joomla | <https://developer.joomla.org/generative-ai-policy.html> | Yes | Yes | Yes | Yes | Cautious |  | Low | Med | Yes | Yes | AI allowed, contributor fully responsible, GPL compatibility required, AI PRs must be labeled, self-review is mandatory, vibe coding is banned, and maintainers may close repeat/problem PRs. |
| Kornia | <https://github.com/kornia/kornia/blob/main/AI_POLICY.md> | Yes | Yes | No | Yes | Cautious | Use AI-generated/AI-assisted/No AI labels. | Low | Med | Yes | Yes | AI usage disclosure labels, and closure for false disclosure or inability to explain. |
| Krita | <https://invent.kde.org/graphics/krita#user-content-ai-moratorium> | No | - | - | - | Rejecting | AI moratorium; to be reviewed October 2026. | Low | Low | N/A | N/A |  |
| Kubernetes | <https://www.kubernetes.dev/docs/guide/pull-requests/#ai-guidance> | Yes | Yes | No | Yes | Cautious | 'Assisted-by:', 'Co-developed-by:' not allowed. | Low | Med | Yes | Yes | AI use must be disclosed, AI cannot be listed as co-author or commit trailer, large AI-generated PRs and AI-generated commit messages are not allowed. PRs can be closed if the author cannot explain the changes. |
| libmanette | <https://gitlab.gnome.org/GNOME/libmanette/-/blob/main/CONTRIBUTING.md?ref_type=heads#use-of-generative-ai> | No | - | - | - | Rejecting |  | Low | Low | N/A | N/A |  |
| LinkML | <https://github.com/linkml/linkml/blob/main/AI_COVENANT.md> | Yes | Yes* | No | Yes | Cautious | No co-authorship with AI tools; disclose when you don't understand the proposed changes. | Low | Med | Yes | Yes |  |
| Linux Kernel | <https://kernel.org/doc/html/next/process/coding-assistants.html> | Yes | Yes | Yes | Yes | Cautious | 'Assisted-by:' required; DCO required. | Low | Low | Yes | Yes |  |
| Linux man-pages | <https://git.kernel.org/pub/scm/docs/man-pages/man-pages.git/tree/CONTRIBUTING.d/ai> | No | - | - | - | Rejecting |  | Low | Low | N/A | N/A |  |
| LLVM | <https://llvm.org/docs//AIToolPolicy.html> | Yes | Yes | Yes | Yes | Cautious | Using AI tools to fix 'good first issues' is forbidden. | High | High | Yes | Yes | No AI fixing “good first issues.” maintainer-burden language, copyright section, and violation handling. |
| LÖVE | <https://github.com/love2d/love#contributing> | No | - | - | - | Rejecting |  | Low | Low | N/A | N/A |  |
| Matplotlib | <https://matplotlib.org/devdocs/devel/contribute.html#restrictions-on-generative-ai-usage> | Yes | Yes | No | Yes | Cautious | 'AI Disclosure' section in PR template must be filled. | Med | Low | Yes | Yes |  |
| MDAnalysis | <https://github.com/MDAnalysis/mdanalysis/blob/develop/AI_POLICY.md> | Yes* | Yes | No | Yes | Restrictive | No 'substantial' contributions generated by AI tools. | Low | Low | Yes | Yes |  |
| Mesa | <https://gitlab.freedesktop.org/mesa/mesa/-/blob/main/docs/submittingpatches.rst?ref_type=heads#id2> | Yes | Yes | Yes | Yes | Cautious | Use 'Assisted-by:' or 'Generated-by:'; do not use 'Co-authored-by:' with AI tools. | Low | Low | Yes | Yes | Contributor is responsible regardless of AI use,  'Co-authored-by:'  is not allowed with AI tools, autonomous tools banned, explicit oversight required, disclosure required. |
| MicroPython | <https://github.com/micropython/micropython/wiki/ContributorGuidelines#generative-ai-policy> | Yes | No | No | Yes | Cautious |  | Low | Low | Yes | Yes |  |
| Molecular Nodes | <https://github.com/BradyAJohnston/MolecularNodes/blob/main/AI_POLICY.md> | Yes* | Yes | No | Yes | Restrictive | No 'substantial' contributions generated by AI tools. | Low | Med | Yes | Yes | AI use must be declared, and maintainers may close PRs that appear poorly understood. |
| napari | <https://napari.org/dev/developers/contributing/ai.html> | Yes | Yes | No | Yes | Cautious |  | Low | Low | Yes | Yes | Shared policy between NumPy, SciPy and NumPy. |
| NetBSD | <https://www.netbsd.org/developers/commit-guidelines.html> | Yes* | Yes | No | No | Restrictive | AI-assisted contributions require explicit core approval. | Low | Low | Yes | Yes |  |
| Cataclysm: Dark Days Ahead | <https://github.com/CleverRaven/Cataclysm-DDA/blob/master/CONTRIBUTING.md#licensing-and-authorship> | No | - | - | - | Rejecting |  | Low | Low | N/A | N/A |  |
| NumPy | <https://numpy.org/devdocs/dev/ai_policy.html> | Yes | Yes | Yes | Yes | Cautious |  | Med | Low | Yes | Yes | Shared policy between NumPy, SciPy and NumPy. |
| nvim-tree | <https://github.com/nvim-tree/nvim-tree.lua?tab=contributing-ov-file#ai-usage-policy-highly-discouraged> | Yes* | Yes | No | Yes | Restrictive | AI generated code is discouraged as this doesn't match nvim-tree values. | Low | Low | Yes | Yes |  |
| OCaml | <https://github.com/ocaml/ocaml/blob/trunk/AI.md> | Yes | Yes | Yes | Yes | Cautious |  | Low | Low | Yes | Yes |  |
| Open edX | <https://github.com/openedx/.github/blob/master/AI_POLICY.md> | Yes* | Yes | No | Yes | Restrictive | Only specific tools with a 'sufficient reputation for proper training' are allowed. | High | Med | Yes | Yes | It is education-related, allows AI with tool restrictions, specifies which tools contributors are allowed to use, requires disclosure, emphasizes understanding and transparency, covers PRs/issues/reviewers, gives good/bad workflow examples, and lets reviewers close AI-driven low-quality review loops. |
| OpenInfra | <https://openinfra.org/legal/ai-policy> | Yes | Yes | Yes | Yes | Cautious | Required use of 'Assisted-by:' or 'Generated-by:'. Open Source AI models recommended. | Low | High | Yes | Yes | requires Assisted-By: / Generated-By:, license compatibility checks,  reviewer checklist. AI-assisted contributions are reviewed more carefully |
| OpenJDK | <https://openjdk.org/legal/ai> | No | - | - | - | Rejecting | Interim policy. | Low | Low | N/A | N/A |  |
| Oxide | <https://rfd.shared.oxide.computer/rfd/0576> | Yes | - | No | Yes | Cautious | Comprehensive, extensive policy. | Med | High | Yes | Yes | Supports understanding rather than replace it. Useful for its warning against relying on AI as a substitute for human code review or comprehension. Uses MPL 2.0. |
| Pandas | <https://pandas.pydata.org/docs/dev/development/contributing.html#automated-contributions-policy> | Yes | Yes | No | Yes | Cautious |  | Med | Low | Yes | Yes |  |
| pgwatch | <https://github.com/cybertec-postgresql/pgwatch/blob/master/AI_POLICY.md> | Yes | Yes | No | Yes | Cautious | Must mention specific tools used. | Low | Low | Yes | Yes |  |
| pip | <https://github.com/pypa/pip/blob/main/AI_POLICY.md> | Yes | No | Yes | Yes | Cautious | No 'Co-authored-by:' with AI tools. | Low | Med | Yes | Yes | Based on the policy of the attrs project. |
| pip-tools | <https://pip-tools.readthedocs.io/en/latest/contributing/#project-contribution-guidelines> | Yes | No | No | Yes | Cautious |  | Low | Low | Yes | Yes |  |
| Polars | <https://github.com/pola-rs/polars/blob/8425c750b9c5d28c79428998fda2320d076d4178/AI_POLICY.md> | Yes | Yes | No | Yes | Cautious |  | Low | Low | Yes | Yes |  |
| postmarketOS | <https://docs.postmarketos.org/policies-and-processes/development/ai-policy.html> | No | - | - | - | Rejecting |  | Low | Low | N/A | N/A |  |
| Processing/p5.js | <https://github.com/processing/processing4/blob/main/AI_USAGE_POLICY.md> | Yes | Yes | No | Yes | Cautious | Disclose specific tools used. | High | High | Yes | Yes | It is education adn community oriented, allows AI only assistively. |
| PyTorch | <https://github.com/pytorch/pytorch/blob/main/CONTRIBUTING.md#ai-assisted-development> | Yes | No | No | Yes | Cautious |  | Low | Low | Yes | Yes |  |
| PyVista | <https://github.com/pyvista/pyvista/blob/main/CONTRIBUTING.rst#generative-ai> | Yes | No | No | Yes | Cautious | Follows CPython's policy. | Low | Low | Yes | Yes | Based on CPython policy. |
| QEMU | <https://www.qemu.org/docs/master/devel/code-provenance.html#use-of-ai-generated-content> | No | - | - | - | Rejecting |  | Low | Low | N/A | N/A |  |
| QGIS | <https://github.com/qgis/QGIS-Enhancement-Proposals/blob/master/qep-408-ai-tool-policy.md> | Yes | Yes | Yes | Yes | Cautious | Use 'Assisted-by:' or 'Generated-by:' labels. | Low | Med | Yes | Yes | New-contributor learning, maintainer-burden language, AI-agent limits, enforcement, and copyright responsibility. |
| qutip | <https://github.com/qutip/qutip/blob/master/CONTRIBUTING.md#ai-tools-usage-policy> | Yes | Yes | Yes | Yes | Cautious | No AI contributions to 'good first issues'. | Low | Low | Yes | Yes |  |
| Redox OS | <https://gitlab.redox-os.org/redox-os/redox/-/blob/master/CONTRIBUTING.md#ai-policy> | No | - | - | - | Rejecting |  | Low | Low | N/A | N/A |  |
| ruff / uv / ty (astral-sh) | <https://github.com/astral-sh/.github/blob/main/AI_POLICY.md> | Yes | No | No | Yes | Cautious |  | Low | Low | Yes | Yes |  |
| SciActive | <https://sciactive.com/human-contribution-policy/> | No | - | - | - | Rejecting |  | Low | Low | N/A | N/A |  |
| scikit-image | <https://scikit-image.org/docs/dev/development/contribute.html#ai-policy> | Yes | Yes | No | Yes | Cautious |  | Low | Med | Yes | Yes | Strong policy, contributors must review code line-by-line. |
| scikit-learn | <https://scikit-learn.org/dev/developers/contributing.html#automated-contributions-policy> | Yes | Yes | No | Yes | Cautious |  | Med | Med | Yes | Yes | no automated AI PRs/issues, contributors must review/test/explain AI changes, and AI use must be stated in the PR. |
| SciPy | <https://scipy.github.io/devdocs/dev/conduct/ai_policy.html> | Yes | Yes | Yes | Yes | Cautious |  | Med | High | Yes | Yes | Required AI disclosure, rejection of AI slop, copyright responsibility, no AI speaking for contributors, and no AI-agent PRs. |
| SDL | <https://github.com/libsdl-org/SDL/blob/main/.github/PULL_REQUEST_TEMPLATE.md> | No | - | - | - | Rejecting | AGENTS.md file bans AI contributions. | Low | Low | N/A | N/A |  |
| SearXNG | <https://github.com/searxng/searxng/blob/master/AI_POLICY.rst> | Yes | Yes | No | Yes | Cautious |  | Low | Low | Yes | Yes |  |
| Servo | <https://book.servo.org/contributing/getting-started.html#ai-contributions> | No | - | - | - | Rejecting |  | Low | Low | N/A | N/A |  |
| STAC | <https://github.com/stac-utils/stac-utils.github.io/blob/main/docs/ai-contribution-policy.md> | Yes | Yes | No | Yes | Cautious | Use 'Assisted-by:' and similar labels. | Low | Low | Yes | Yes |  |
| stb | <https://github.com/nothings/stb/blob/master/CONTRIBUTING.md#ai-and-llm-are-forbidden> | No | - | - | - | Rejecting |  | Low | Low | N/A | N/A |  |
| SymPy | <https://docs.sympy.org/dev/contributing/ai-generated-code-policy.html> | Yes | Yes | Yes | Yes | Cautious |  | Med | Low | Yes | Yes | Shared policy between NumPy, SciPy and NumPy |
| Telegraf | <https://github.com/influxdata/telegraf?tab=contributing-ov-file#ai-generated-code> | No | - | - | - | Rejecting |  | Low | Low | N/A | N/A |  |
| typescript-eslint | <https://typescript-eslint.io/contributing/ai-policy/> | Yes | No | No | Yes | Cautious |  | Low | Low | Yes | Yes |  |
| Unison | <https://github.com/bcpierce00/unison/blob/master/CONTRIBUTING.md#llm-usage> | No | - | - | - | Rejecting |  | Low | Low | N/A | N/A |  |
| University of Alaska Anchorage (GSoC) | <https://github.com/uaanchorage/GSoC/blob/main/Acceptable-and-Ethical-AI-Use-Policy.md> | Yes* | No | No | Yes | Restrictive | No vibe code. | High | High | Yes | Yes | It is explicitly student/GSoC-focused. It allows limited AI help but rejects vibe coding, AI slop, untested code, bloated AI communication, and AI-heavy research/proposals. Very useful for OED’s educational mission. |
| Vim Classic | <https://sr.ht/~sircmpwn/vim-classic/> | No | - | - | - | Rejecting |  | Low | Low | N/A | N/A |  |
| Wagtail | <https://docs.wagtail.org/en/latest/contributing/general_guidelines.html#general-coding-guidelines> | Yes | Yes | No | Yes | Cautious |  | Med | Low | Yes | Yes |  |
| Wikipedia (German/English) | <https://en.wikipedia.org/wiki/Wikipedia:Artificial_intelligence> | No* | - | - | - | Rejecting |  | Low | Low | N/A | N/A |  |
| WP1 | <https://github.com/openzim/wp1/blob/main/CONTRIBUTING.md#usage-of-llmsai-coding-assistants> | Yes | No | No | Yes | Cautious |  | Low | Low | Yes | Yes |  |
| XScreenSaver | <https://www.jwz.org/xscreensaver/faq.html#writing-savers> | No | - | - | - | Rejecting |  | Low | Low | N/A | N/A |  |
| Zig | <https://ziglang.org/code-of-conduct/#strict-no-llm-no-ai-policy> | No | - | - | - | Rejecting | Contributor Poker and Zig's AI Ban — rationale for ban documented separately. | Low | Low | N/A | N/A |  |
| Zulip | <https://github.com/zulip/zulip/blob/main/CONTRIBUTING.md#ai-use-policy-and-guidelines> | Yes | No | Yes | Yes | Cautious |  | Low | High | Yes | Yes | Contributors must understand/explain/test changes, avoid vibe coding, avoid AI slop, communicate clearly, and maintainers may close AI-generated PRs that waste review time. GSoC. |

## High-Med Relevant Policies

NOTE: Filtered list of AI policies with Medium/High relevance to OED’s student-focused context and Medium/High usefulness for OED policy design.<br>Data and policy information current as of August 2026, based on publicly available information from the cited project websites and repositories.

| Project Name | Policy Link | AI Allowed<br>(source table) | Disclosure Required<br>(source table) | Copyright Stmt<br>(source table) | Human in Loop<br>(source table) | Stance | Source Notes (Source table) | Relevance to OED/ Student | Policy Relevance to OED | Contributor<br>Responsible? | Human Review<br>Required? | Comments |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| Apache Software Foundation (ASF) | <https://www.apache.org/legal/generative-tooling.html> | Yes | Yes | Yes | - | Cautious | Applies to all ASF projects; enforcement decentralized. Requires 'Generated-by:' in commit message. | Med | High | Yes | Not explicitly stated. | Important because it gives broad open-source legal guidance on generative tooling, disclosure, and licensing. |
| CCExtractor | <https://ccextractor.org/public/gsoc/ai_policy/> | Yes | Yes | Yes | Yes | Cautious | Mark PRs as AI-generated/AI-assisted/No AI used | High | High | Yes | Yes | Sole Responsible Author, it has a student/GSoC context and clear PR labeling for AI-generated, AI-assisted, or no-AI work. |
| CPython | <https://devguide.python.org/getting-started/ai-tools/index.html> | Yes | No | No | Yes | Cautious | Disclosure of AI tools appreciated, not required. | Med | High | Yes | Yes | Strong emphasis on focused changes, existing coding patterns, tests. Disclosure is only encouraged, not required |
| Drupal | <https://www.drupal.org/docs/develop/issues/issue-procedures-and-etiquette/policy-on-the-use-of-ai-when-contributing-to-drupal> | Yes | Yes | Yes | Yes | Cautious |  | Med | High | Yes | Yes | Strong responsibility language, copyright and licensing rules, disclosure thresholds, examples of bad AI use, enforcement, and a GSoC/student-learning note. |
| Firefox | <https://firefox-source-docs.mozilla.org/contributing/ai-coding.html> | Yes | No | No | Yes | Cautious |  | Med | High | Yes | Yes | It explicitly says humans remain accountable, must understand and self-review the code, must protect sensitive data, and should not use AI to bypass learning on “Good First” / “Good Next” bugs. The learning-focused language is useful for OED. |
| LLVM | <https://llvm.org/docs//AIToolPolicy.html> | Yes | Yes | Yes | Yes | Cautious | Using AI tools to fix 'good first issues' is forbidden. | High | High | Yes | Yes | No AI fixing “good first issues.” maintainer-burden language, copyright section, and violation handling. |
| Open edX | <https://github.com/openedx/.github/blob/master/AI_POLICY.md> | Yes* | Yes | No | Yes | Restrictive | Only specific tools with a 'sufficient reputation for proper training' are allowed. | High | Med | Yes | Yes | It is education-related, allows AI with tool restrictions, specifies which tools contributors are allowed to use, requires disclosure, emphasizes understanding and transparency, covers PRs/issues/reviewers, gives good/bad workflow examples, and lets reviewers close AI-driven low-quality review loops. |
| Oxide | <https://rfd.shared.oxide.computer/rfd/0576> | Yes | - | No | Yes | Cautious | Comprehensive, extensive policy. | Med | High | Yes | Yes | Supports understanding rather than replace it. Useful for its warning against relying on AI as a substitute for human code review or comprehension. Uses MPL 2.0. |
| Processing/p5.js | <https://github.com/processing/processing4/blob/main/AI_USAGE_POLICY.md> | Yes | Yes | No | Yes | Cautious | Disclose specific tools used. | High | High | Yes | Yes | It is education adn community oriented, allows AI only assistively. |
| scikit-learn | <https://scikit-learn.org/dev/developers/contributing.html#automated-contributions-policy> | Yes | Yes | No | Yes | Cautious |  | Med | Med | Yes | Yes | no automated AI PRs/issues, contributors must review/test/explain AI changes, and AI use must be stated in the PR. |
| SciPy | <https://scipy.github.io/devdocs/dev/conduct/ai_policy.html> | Yes | Yes | Yes | Yes | Cautious |  | Med | High | Yes | Yes | Required AI disclosure, rejection of AI slop, copyright responsibility, no AI speaking for contributors, and no AI-agent PRs. |
| University of Alaska Anchorage (GSoC) | <https://github.com/uaanchorage/GSoC/blob/main/Acceptable-and-Ethical-AI-Use-Policy.md> | Yes* | No | No | Yes | Restrictive | No vibe code. | High | High | Yes | Yes | It is explicitly student/GSoC-focused. It allows limited AI help but rejects vibe coding, AI slop, untested code, bloated AI communication, and AI-heavy research/proposals. Very useful for OED’s educational mission. |

## Findings & Synthesis

Research Findings - OED AI Policy Comparison<br>Data and policy information current as of August 2026, based on publicly available information from the cited project websites and repositories.

### OVERALL POLICY LANDSCAPE

| Finding | Count | Total reviewed | Percentage | Scope |
| --- | --- | --- | --- | --- |
| Projects allowing AI-assisted contributions | 71 | 110 | 64.5% | All projects |
| Projects rejecting AI-assisted contributions | 39 | 110 | 35.5% | All projects |

### CONTRIBUTOR ACCOUNTABILITY & HUMAN REVIEW & DISCLOSURE

| Finding | Count | Total reviewed | Percentage | Scope |
| --- | --- | --- | --- | --- |
| Contributor responsibility required | 69 | 71 | 97.2% | All AI Allowing projects |
| Human review required | 68 | 71 | 95.8% | All AI Allowing projects |
| Disclosure required | 47 | 71 | 66.2% | All AI Allowing projects |

### Relevance

| Finding | Count | Total reviewed | Percentage | Scope |
| --- | --- | --- | --- | --- |
| Relevent projects require human review | 11 | 12 | 92.0% | High-Med relevance |
| Relevent projects require contributor accountability | 12 | 12 | 100.0% | High-Med relevance |