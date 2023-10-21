let render request =
  let open Tyxml.Html in
  let html =
    Layout.Default.layout
      ~title:"Terms of Service"
      [ div ~a:[ a_style "max-width: 1600px" ]
        [ h3 [ txt "1. Acceptance of Terms" ]
        ; p [ txt "By accessing or using this open-source website, you are agreeing to be bound by these Terms of Service, all applicable laws, and regulations, and agree that you are responsible for compliance with any applicable local laws." ]
        ; h3 [ txt "2. Open Source Disclaimer" ]
        ; p [ txt "This website is open-source, which means that the source code is made available for anyone to view, modify, and distribute under the terms of the applicable open-source license." ]
        ; h3 [ txt "3. Comment Section Disclaimer" ]
        ; p [ txt "The comment section on our open-source website is provided for user-generated content. We are not liable for any comments posted by users. Any opinions expressed in the comments are those of the individual users and do not necessarily reflect our views or opinions." ]
        ; h3 [ txt "4. Disclaimer" ]
        ; p [ txt "The materials on our open-source website are provided \"as is\". We make no warranties, expressed or implied, and hereby disclaim and negate all other warranties, including without limitation, implied warranties or conditions of merchantability, fitness for a particular purpose, or non-infringement of intellectual property or other violation of rights." ]
        ; h3 [ txt "5. Limitations" ]
        ; p [ txt "In no event shall we be liable for any damages (including, without limitation, damages for loss of data or profit, or due to business interruption) arising out of the use or inability to use the materials on our open-source website, even if we or an authorized representative have been notified orally or in writing of the possibility of such damage." ]
        ; h3 [ txt "6. Revisions and Errata" ]
        ; p [ txt "The materials appearing on our open-source website could include technical, typographical, or photographic errors. We do not warrant that any of the materials on its website are accurate, complete, or current." ]
        ; h3 [ txt "7. Links" ]
        ; p [ txt "We have not reviewed all of the sites linked to its open-source website and are not responsible for the contents of any such linked site. The inclusion of any link does not imply endorsement by us." ]
        ; h3 [ txt "8. Governing Law" ]
        ; p [ txt "Any claim relating to our open-source website shall be governed by the laws of Canada without regard to its conflict of law provisions." ]
        ; h3 [ txt "9. Contact Us" ]
        ; p [ txt "If you have any questions about these Terms of Service, please contact us at contact@readingtree.app." ]
        ]
      ]
      request
  in
  Render.to_string html