import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nyrna/application/preferences/cubit/preferences_cubit.dart';
import 'package:nyrna/presentation/core/core.dart';

import '../../styles.dart';

class BehaviourSection extends StatelessWidget {
  const BehaviourSection({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Behaviour'),
        Spacers.verticalXtraSmall,
        ListTile(
          title: const Text('Auto Refresh'),
          leading: const Icon(Icons.refresh),
          subtitle: const Text('Update window & process info automatically'),
          trailing: BlocBuilder<PreferencesCubit, PreferencesState>(
            builder: (context, state) {
              return Switch(
                value: state.autoRefresh,
                onChanged: (value) async {
                  await preferencesCubit.updateAutoRefresh(value);
                },
              );
            },
          ),
        ),
        BlocBuilder<PreferencesCubit, PreferencesState>(
          builder: (context, state) {
            return ListTile(
              leading: const Icon(Icons.timelapse),
              title: const Text('Auto Refresh Interval'),
              trailing: Text('${state.refreshInterval} seconds'),
              enabled: state.autoRefresh,
              onTap: () => _refreshIntervalDialog(context),
            );
          },
        ),
      ],
    );
  }

  /// Allow user to choose reset interval.
  void _refreshIntervalDialog(BuildContext context) async {
    final result = await showInputDialog(
      context: context,
      type: InputDialogs.onlyInt,
      title: 'Auto Refresh Interval',
      initialValue: preferencesCubit.state.refreshInterval.toString(),
    );
    if (result == null) return;
    final newInterval = int.tryParse(result);
    if (newInterval == null) return;
    await preferencesCubit.setRefreshInterval(newInterval);
    await preferencesCubit.updateAutoRefresh();
  }
}
