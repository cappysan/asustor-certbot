# Cappysan's Asustor Certbot APK

Asustor APK package for Certbot, the free, open source software tool certificate generator.


## Table of contents
1. [Installation](#installation)  
2. [Usage](#usage)  
3. [Support & Sponsorship](#support)  
4. [License](#license)  
5. [Links](#links)  


## Installation <a name="installation"></a>

The APK application is available as a GitLab release, and on [https://asustor.cappysan.dev/](https://asustor.cappysan.dev/)

The APK application is not available as an Asustor App Central application as Asustor does not accept duplicates nor applications without a UI.


## Usage <a name="usage"></a>


### Installing

- Download the APK file from Cappysan's Asustor website ([https://asustor.cappysan.dev/certbot](https://asustor.cappysan.dev/certbot)  
- In AppCentral, "Management", "Manual Install", install the package.


### Configuration

Configuration of the package requires the ability to edit the files in the **Configuration** shared folder. A few methods that can be used to edit the files:

- Using SSH, and modifying the files directly in the "/share/Configuration" folder.
- Mounting the **Configuration** shared folder, either via NFS, SMB, or some other mount protocol.
- Downloading, edition, and re-uploading the files via the internal "File Explorer"

Once you are able to modify files in the **Configuration** shared folder, you must configure the following files:

- In the "cerbot" folder, edit "domains.conf" with the domains to get a cert for. eg: "\*.example.com". Wildcard certificates are accepted.
- In the "cerbot" folder, edit "provider.conf" with the name of DNS validator you will use. You can use any other value as long as you create a cmdline for that provider.
- In the "cerbot" folder, edit "credentials.conf" or "<provider>.conf" with credentials you will use. 
- An optional "cmdline.conf" file can be created to override the DNS specific certbot command line.
- De-activate and re-activate the application to generate the certificates;
- Verify in the builtin syslog viewer on the NAS interface that certificate generation was a success, or not.
- Download the "certificates.zip" from the certbot configuration folder,
- Add those certificates to the Certificate Manager and select this certificate as the default certificate.


## Support & Sponsorship <a name="support"></a>

You can help support this project, and all Cappysan projects, through the following actions:

- ⭐ Star the repository on GitLab, GitHub, or both to increase visibility and community engagement.

- 💬 Join the Discord community: [https://discord.gg/SsY3CAdp4Q](https://discord.gg/SsY3CAdp4Q) to connect, contribute, share feedback, and/or stay updated.

- 🛠️ Contribute by submitting issues, improving documentation, or creating pull requests to help the project grow.

- ☕ Support financially through [Buy Me a Coffee](https://buymeacoffee.com/cappysan), [GitHub](https://github.com/sponsors/cappysan), or [Bitcoin (bc1qaz86l247df34h2q657c6zfs5l33r76s4ewxg4v)](https://addrs.to/pay/BTC/bc1qaz86l247df34h2q657c6zfs5l33r76s4ewxg4v). Your contributions directly sustain ongoing development and maintenance, including server costs.

Your support ensures these projects continue to improve, expand, and remain freely available to everyone.


## License <a name="license"></a>

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

Please refer to the upstream software documentation for details on their respective licenses.


## Links <a name="links"></a>

  * Cappysan's Asustor Tutorials & Procedures: [https://blog.cappysan.dev/asustor/index.html](https://blog.cappysan.dev/asustor/index.html)
  * Cappysan's Asustor applications website: [https://asustor.cappysan.dev/](https://asustor.cappysan.dev/)
  * GitLab: [https://gitlab.com/cappysan/asustor/certbot](https://gitlab.com/cappysan/asustor/certbot)
  * GitHub: [https://github.com/cappysan/asustor-certbot](https://github.com/cappysan/asustor-certbot)
  * Discord: [https://discord.gg/SsY3CAdp4Q](https://discord.gg/SsY3CAdp4Q)
