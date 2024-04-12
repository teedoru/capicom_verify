
Сервис для проверки отсоединенной электронной подписи.

Проверка осуществляется с помощью библиотеки Capicom от Microsoft.

**Использование**
Отправить **POST** запрос на http://localhost:8080/api/verify

|Ключ|Значение|
|-|--------|
|content_file| Исходный файл документа|
|signature_file| Файл подписи|


**Пример:**
```php
<?php

$curl_files = array(
  'signature_file' => curl_file_create('path', 'application/pgp-signature', 'contract.pdf.sig'),
  'content_file' =>  curl_file_create('path', 'application/pdf', 'contract.pdf')
);

$ch = curl_init('http://localhost:743/api/verify');
curl_setopt($ch, CURLOPT_POST, 1);
curl_setopt($ch, CURLOPT_POSTFIELDS, $curl_files);
curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
curl_setopt($ch, CURLOPT_SSL_VERIFYPEER, false);
curl_setopt($ch, CURLOPT_HEADER, false);
$response = curl_exec($ch);
curl_close($ch);

echo json_decode($response);
```

**Успешный ответ**
```json
{
    "Verify": true,
    "Certificate": {
        "SubjectName": "",
        "IssuerName": "",
        "SerialNumber": "",
        "Thumbprint": "",
        "ValidFromDate": "",
        "ValidToDate": "",
        "Version": "",
        "SigningTime": ""
    }
}

```

**Где скачать Capicom и как зарегистрировать**

[Ссылка 1](https://www.sberbank-ast.ru/Docs/faq/%D0%A3%D1%81%D1%82%D0%B0%D0%BD%D0%BE%D0%B2%D0%BA%D0%B0_%D0%B1%D0%B8%D0%B1%D0%BB%D0%B8%D0%BE%D1%82%D0%B5%D0%BA%D0%B8_Capicom.pdf "www.sberbank-ast.ru"), [Ссылка 2](https://dirstroy.dogm.mos.ru/legislation/information-from-the-department-of-municipal-order/instructions-for-configuring-eds/ "wdirstroy.dogm.mos.ru"), [Ссылка 3](https://support.gamemc.by/index.php?/Knowledgebase/Article/View/35 "support.gamemc.by"), [Ссылка 4](https://legacyupdate.net/download-center/download/3207/security-update-for-capicom-kb931906 "legacyupdate.net")

**Криптопровайдер**
КриптоПро CSP или ViPNet CSP

В качестве HTTP сервера [delphimvcframework](https://github.com/danieleteti/delphimvcframework "delphimvcframework")



