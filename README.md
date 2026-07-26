>[!warning] This scripts is only for **GNOME** DE on Fedora.

# For testing purposes:

1. Allow port 8000 in the firewall:
```
sudo firewall-cmd --zone=libvirt --add-port=8000/tcp
```
2. Start the server:
```
python3 -m http.server 8000
```
3. Fast
```
sudo fuser -k 8000/tcp; sudo firewall-cmd --zone=libvirt --add-port=8000/tcp && python3 -m http.server 8000
```

>[!NOTE]
> Must be run at the directory where `setup.sh` is located.

3. On the virtual machine, use this command to get the content and run `setup.sh`:

```
wget -r -np -nH -R "index.html*" http://192.168.122.1:8000/ && chmod +x ./setup.sh && ./setup.sh
```

## Test Fcitx5

```
sudo dnf remove -y fcitx5 fcitx5-unikey fcitx5-gtk fcitx5-qt && \
rm -rf ~/.config/fcitx5 ~/.config/environment.d/fcitx5.conf ~/.config/imsettings/xinputrc ~/.config/autostart/org.fcitx.Fcitx5.desktop ~/.config/autostart/resume-setup-fedora.desktop
```