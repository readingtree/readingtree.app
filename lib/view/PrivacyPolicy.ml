let render request =
  let open Tyxml.Html in
  let html = 
    Layout.Default.layout
      ~title:"Privacy Policy"
      [ div ~a:[ a_style "max-width: 1600px" ]
        [ h2 [ txt "Privacy Policy" ] 
        ; p [ txt "Reading Tree (referred to as \"we\", \"us\", or \"our\") operates the website located at readingtree.app (the \"Site\"). This page informs you of our policies regarding the collection, use, and disclosure of personal information we receive from users of the Site." ]
        ; h3 [ txt "Information Collection and Use" ]
        ; p [ txt "While using our Site, we may ask you to provide us with certain personally identifiable information that can be used to contact or identify you. Personally identifiable information may include, but is not limited to, your name, email address, and other information (\"Personal Information\"). " ]
        ; h3 [ txt "Log Data" ]
        ; p [ txt "Like many site operators, we collect information that your browser sends whenever you visit our Site (\"Log Data\"). This Log Data may include information such as your computer's Internet Protocol (\"IP\") address, browser type, browser version, the pages of our Site that you visit, the time and date of your visit, the time spent on those pages, and other statistics." ]
        ; h3 [ txt "Cookies" ]
        ; p [ txt "Cookies are files with small amount of data, which may include an anonymous unique identifier. Cookies are sent to your browser from a web site and stored on your computer's hard drive." ]
        ; h3 [ txt "Security" ]
        ; p [ txt "The security of your Personal Information is important to us, but remember that no method of transmission over the Internet, or method of electronic storage, is 100% secure. While we strive to use commercially acceptable means to protect your Personal Information, we cannot guarantee its absolute security." ]
        ; h3 [ txt "Changes to This Privacy Policy" ]
        ; p [ txt "This Privacy Policy is effective as of October 21, 2023 and will remain in effect except with respect to any changes in its provisions in the future, which will be in effect immediately after being posted on this page." ]
        ; h3 [ txt "Contact Us" ]
        ; p [ txt "If you have any questions about this Privacy Policy, please contact us at contact@readingtree.app." ]
        ]
      ]
      request
  in
  Render.to_string html