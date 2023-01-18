# frozen_string_literal: true

module Articles
  class Export
    class << self
      def get_html_fr(article)
        '<!DOCTYPE html>
                <html>
                  <head>
                    <meta http-equiv="Content-Type" content="text/html; charset=utf-8" />
                <style>
                      div.alwaysbreak { page-break-before: always; }
                div.nobreak:before { clear:both; }
                div.nobreak { page-break-inside: avoid; }
                    </style>
                  </head>
                  <body>

                <div leftmargin="0" marginwidth="0" topmargin="0" marginheight="0" offset="0"
                      style="height:auto !important;width:100% !important; margin-bottom: 40px;">
                      <div class="justify-content-center d-flex">
                        <table bgcolor="#ffffff" border="0" cellpadding="0" cellspacing="0"
                          style="max-width:600px; background-color:#ffffff;border:1px solid #e4e2e2;border-collapse:separate !important; border-radius:10px;border-spacing:0;color:#242128; margin:0;padding:40px;"
                          heigth="auto">
                          <tbody>
                            <tr>
                              <td align="left" valign="center"
                              style="padding-bottom:40px;border-top:0;height:100% !important;width:150px !important;">
                                <img style="height:100px" src="' + 'https://api.mediasecho.com' + article.medium.avatar.url + ' " />
                              </td>
                              <td align="right" valign="center"
                                style="padding-bottom:40px;border-top:0;height:100% !important;width:auto !important;">
                                <span style="color: #8f8f8f; font-weight: normal; line-height: 2; font-size: 14px;"> ' + article.author.name + ' | ' + article.date_published.strftime('%d - %m - %Y') + '</span>
                              </td>
                <td align="center" valign="center"
                                style="padding-bottom:40px;border-top:0;height:100% !important;width:auto !important;">

                              </td>
                            </tr>
                            <tr>
                              <td colSpan="2" style="padding-top:10px;border-top:1px solid #e4e2e2">
                                <h2 style="color:#303030; font-size:20px; line-height: 1.6; font-weight:500;"><b>' + article.title + '</b> </h2>
                                ' + article.body + '
                              </td>
                            </tr>
                          </tbody>
                        </table>
                      </div>
                      <div align="center">
                        <table style="margin-top:30px; padding-bottom:20px;; margin-bottom: 40px;">
                          <tbody>
                            <tr>
                              <td align="center" valign="center">
                                <p
                                  style="font-size: 12px;line-height: 1; color:#909090; margin-top:0px; margin-bottom:5px; ">
                                  PDF généré par MediasEcho app le ' + Date.today.strftime('%d - %m - %Y') + '
                                </p>
                                <p style="font-size: 12px; line-height:1; color:#909090;  margin-top:5px; margin-bottom:5px;">
                                  <a href="#" style="color: #00365a;text-decoration:none;">Alger</a> , <a href="#"
                                    style="color: #00365a;text-decoration:none; ">Algerie</a>
                                </p>
                              </td>
                            </tr>
                          </tbody>
                        </table>
                      </div>
                    </div>
                  </body>
                </html>'
      end

      def get_html_ar(article)
        '<!DOCTYPE html>
                <html>
                  <head>
                    <meta http-equiv="Content-Type" content="text/html; charset=utf-8" />
                <style>
                      div.alwaysbreak { page-break-before: always; }
                div.nobreak:before { clear:both; }
                div.nobreak { page-break-inside: avoid; }
                    </style>
                  </head>
                  <body>

                <div leftmargin="0" marginwidth="0" topmargin="0" marginheight="0" offset="0"
                      style="height:auto !important;width:100% !important; margin-bottom: 40px;">
                      <div class="justify-content-center d-flex">
                        <table bgcolor="#ffffff" border="0" cellpadding="0" cellspacing="0"
                          style="max-width:600px; background-color:#ffffff;border:1px solid #e4e2e2;border-collapse:separate !important; border-radius:10px;border-spacing:0;color:#242128; margin:0;padding:40px;"
                          heigth="auto">
                          <tbody>
                            <tr>
                              <td align="left" valign="center"
                              style="padding-bottom:40px;border-top:0;height:100% !important;width:30% !important;">
                                <img style="height:100px" src="' + 'https://api.mediasecho.com' + article.medium.avatar.url + ' " />
                              </td>
                              <td align="right" valign="center"
                                style="padding-bottom:40px;border-top:0;height:100% !important;width:auto  !important;">
                                <span style="color: #8f8f8f; font-weight: normal; line-height: 2; font-size: 14px;">' + article.author.name + ' | ' + article.date_published.strftime('%d - %m - %Y') + '</span>
                              </td>
                            <td align="center" valign="center"
                                style="padding-bottom:40px;border-top:0;height:100% !important;width:auto !important;">

                              </td>
                            </tr>
                            <tr>
                              <td colSpan="2" style="padding-top:10px;border-top:1px solid #e4e2e2;direction: rtl;">
                                <h2 style="color:#303030; font-size:20px; line-height: 1.6; font-weight:500;direction: rtl;"><b>' + article.title + ' </b></h2>
                                ' + article.body + '
                              </td>
                            </tr>
                          </tbody>
                        </table>
                      </div>
                      <div align="center">
                        <table style="margin-top:30px; padding-bottom:20px;; margin-bottom: 40px;">
                          <tbody>
                            <tr>
                              <td align="center" valign="center">
                                <p
                                  style="font-size: 12px;line-height: 1; color:#909090; margin-top:0px; margin-bottom:5px; ">
                                  PDF généré par MediasEcho app le ' + Date.today.strftime('%d - %m - %Y') + '
                                </p>
                                <p style="font-size: 12px; line-height:1; color:#909090;  margin-top:5px; margin-bottom:5px;">
                                  <a href="#" style="color: #00365a;text-decoration:none;">Alger</a> , <a href="#"
                                    style="color: #00365a;text-decoration:none; ">Algerie</a>
                                </p>
                              </td>
                            </tr>
                          </tbody>
                        </table>
                      </div>
                    </div>
                  </body>
                </html>'
      end
    end
  end
end
