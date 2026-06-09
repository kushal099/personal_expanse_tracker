import 'package:flutter/material.dart';

/// Settings group title
class SettingsGroupTitle extends StatelessWidget {
  final String title;

  const SettingsGroupTitle({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 16, top: 24, bottom: 8),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
          fontWeight: FontWeight.bold,
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
    );
  }
}

/// Settings switch tile
class SettingsSwitchTile extends StatelessWidget {
  final String title;
  final String? subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;
  final IconData icon;

  const SettingsSwitchTile({
    super.key,
    required this.title,
    this.subtitle,
    required this.value,
    required this.onChanged,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      subtitle: subtitle != null ? Text(subtitle!) : null,
      trailing: Switch(value: value, onChanged: onChanged),
    );
  }
}

/// Settings selection tile
class SettingsSelectionTile extends StatelessWidget {
  final String title;
  final String? subtitle;
  final String currentValue;
  final VoidCallback onTap;
  final IconData icon;

  const SettingsSelectionTile({
    super.key,
    required this.title,
    this.subtitle,
    required this.currentValue,
    required this.onTap,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      subtitle: subtitle != null ? Text(subtitle!) : Text(currentValue),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }
}

/// Settings button tile
class SettingsButtonTile extends StatelessWidget {
  final String title;
  final String? subtitle;
  final VoidCallback onTap;
  final IconData icon;
  final Color? textColor;

  const SettingsButtonTile({
    super.key,
    required this.title,
    this.subtitle,
    required this.onTap,
    required this.icon,
    this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: textColor),
      title: Text(title, style: TextStyle(color: textColor)),
      subtitle: subtitle != null
          ? Text(
              subtitle!,
              style: TextStyle(color: textColor?.withValues(alpha: 0.7)),
            )
          : null,
      trailing: Icon(Icons.chevron_right, color: textColor),
      onTap: onTap,
    );
  }
}

/// Settings dropdown dialog
class SettingsDropdownDialog extends StatelessWidget {
  final String title;
  final List<String> options;
  final String currentOption;
  final ValueChanged<String> onSelected;

  const SettingsDropdownDialog({
    super.key,
    required this.title,
    required this.options,
    required this.currentOption,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return SimpleDialog(
      title: Text(title),
      children: options
          .map(
            (option) => SimpleDialogOption(
              onPressed: () {
                onSelected(option);
                Navigator.pop(context);
              },
              child: Row(
                children: [
                  Expanded(child: Text(option)),
                  if (option == currentOption)
                    Icon(
                      Icons.check,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                ],
              ),
            ),
          )
          .toList(),
    );
  }
}

/// App info tile
class AppInfoTile extends StatelessWidget {
  final String label;
  final String value;

  const AppInfoTile({super.key, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: colorScheme.onSurfaceVariant),
          ),
          Text(
            value,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}
