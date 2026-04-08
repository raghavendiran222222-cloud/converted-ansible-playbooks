# win_base_config

Ansible role for base Windows Server configuration. Converted from the PowerShell provisioning scripts `25_Misc.ps1` and `25_Misc_EST.ps1`.

## Purpose

Applies baseline system settings to Windows Server hosts including:

- Disabling Network Location Wizard
- Disabling ServerManager autostart
- Setting the power plan to High Performance
- Configuring Internet Explorer (start page, first-run wizard)
- Disabling Action Center / toast notifications
- Enabling Remote Desktop (RDP)
- Moving the Start menu to left alignment (Server 2025)
- Setting keyboard languages and system culture
- Setting the timezone

## Requirements

- Ansible 2.14+
- Collections: `ansible.windows`, `community.windows`
- Target hosts must be Windows Server 2019, 2022, or 2025

## Role Variables

| Variable | Default | Description |
|---|---|---|
| `win_base_config_timezone` | `W. Europe Standard Time` | Windows timezone name |
| `win_base_config_culture` | `sv-SE` | System culture / locale |
| `win_base_config_languages` | `["sv-SE", "en-US"]` | Keyboard language list |
| `win_base_config_ie_start_page` | `about:blank` | IE default start page |
| `win_base_config_enable_rdp` | `true` | Enable Remote Desktop |
| `win_base_config_disable_action_center` | `true` | Disable Action Center and toast notifications |
| `win_base_config_disable_server_manager` | `true` | Disable ServerManager scheduled task |
| `win_base_config_disable_network_location_wizard` | `true` | Disable Network Location Wizard |
| `win_base_config_disable_ie_wizard` | `true` | Disable IE First Run Wizard |
| `win_base_config_set_high_performance_power` | `true` | Set power plan to High Performance |
| `win_base_config_move_start_to_left` | `false` | Move Start menu to left (2025 only) |
| `win_base_config_os_version` | `2025` | Target OS version for version-specific tasks |

## Example Playbook

```yaml
---
- name: Apply base Windows configuration
  hosts: windows_servers
  gather_facts: true
  roles:
    - role: win_base_config
      vars:
        win_base_config_timezone: "Eastern Standard Time"
        win_base_config_culture: "en-US"
        win_base_config_languages:
          - "en-US"
        win_base_config_move_start_to_left: true
        win_base_config_os_version: "2025"
```

## Testing

1. Run the role against a test Windows host:

   ```bash
   ansible-playbook -i inventory test_win_base_config.yml
   ```

2. Verify on the target host:
   - `Get-TimeZone` returns the configured timezone
   - `Get-Culture` returns the configured culture
   - `Get-WinUserLanguageList` shows the configured languages
   - RDP is accessible (port 3389 open)
   - `powercfg /getactivescheme` shows High Performance
   - ServerManager does not launch on login

## License

Proprietary - Xylem

## Author

Xylem (converted from PowerShell by automation pipeline)
