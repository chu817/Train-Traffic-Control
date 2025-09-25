from datetime import datetime
import statistics

class KPICalculator:
    def __init__(self):
        self.metrics = {}
        
    def calculate_kpis(self, scheduled_trains, actual_performance=None):
        """
        Calculate key performance indicators
        """
        if not scheduled_trains:
            return {}
            
        # Use actual performance if available, otherwise use scheduled
        performance_data = actual_performance or scheduled_trains
        
        # 1. Punctuality Rate
        punctuality = self.calculate_punctuality(performance_data)
        
        # 2. Average Delay
        avg_delay = self.calculate_average_delay(performance_data)
        
        # 3. Throughput
        throughput = self.calculate_throughput(performance_data)
        
        # 4. Track Utilization
        utilization = self.calculate_track_utilization(performance_data)
        
        # 5. Priority Performance
        priority_performance = self.calculate_priority_performance(performance_data)
        
        kpis = {
            'punctuality_rate': round(punctuality, 2),
            'average_delay_minutes': round(avg_delay, 2),
            'throughput_trains_per_hour': round(throughput, 2),
            'track_utilization_percent': round(utilization, 2),
            'priority_performance': priority_performance,
            'total_trains': len(performance_data),
            'on_time_trains': sum(1 for t in performance_data.values() if t.get('delay_minutes', 0) <= 5),
            'delayed_trains': sum(1 for t in performance_data.values() if t.get('delay_minutes', 0) > 5),
            'cancelled_trains': sum(1 for t in performance_data.values() if t.get('status') == 'cancelled')
        }
        
        return kpis
    
    def calculate_punctuality(self, trains):
        """
        Punctuality: % of trains with delay <= 5 minutes
        """
        if not trains:
            return 0
            
        on_time_count = 0
        total_count = len(trains)
        
        for train_data in trains.values():
            delay = train_data.get('delay_minutes', 0)
            if delay <= 5:  # Consider 5 min as on-time
                on_time_count += 1
        
        return (on_time_count / total_count) * 100
    
    def calculate_average_delay(self, trains):
        """
        Average delay across all trains
        """
        if not trains:
            return 0
            
        delays = [train_data.get('delay_minutes', 0) for train_data in trains.values()]
        return statistics.mean(delays)
    
    def calculate_throughput(self, trains):
        """
        Trains per hour (simplified calculation)
        """
        if not trains:
            return 0
            
        # Assume 24-hour window
        return len(trains) / 24
    
    def calculate_track_utilization(self, trains):
        """
        % of time tracks are occupied (simplified)
        """
        if not trains:
            return 0
            
        # Simplified calculation
        # In reality, need actual track occupation times
        total_train_hours = 0
        
        for train_data in trains.values():
            # Assume average journey time of 2 hours
            journey_time = 2
            total_train_hours += journey_time
        
        # Assume 10 tracks available, 24 hours
        available_track_hours = 10 * 24
        
        return min(100, (total_train_hours / available_track_hours) * 100)
    
    def calculate_priority_performance(self, trains):
        """
        Performance breakdown by train priority
        """
        priority_groups = {'passenger': [], 'express': [], 'freight': []}
        
        for train_data in trains.values():
            # Map priority number back to type
            if train_data.get('priority', 5) == 1:
                priority_groups['passenger'].append(train_data.get('delay_minutes', 0))
            elif train_data.get('priority', 5) == 2:
                priority_groups['express'].append(train_data.get('delay_minutes', 0))
            else:
                priority_groups['freight'].append(train_data.get('delay_minutes', 0))
        
        performance = {}
        for group, delays in priority_groups.items():
            if delays:
                performance[group] = {
                    'count': len(delays),
                    'avg_delay': round(statistics.mean(delays), 2),
                    'punctuality': round((sum(1 for d in delays if d <= 5) / len(delays)) * 100, 2)
                }
            else:
                performance[group] = {'count': 0, 'avg_delay': 0, 'punctuality': 100}
        
        return performance
    
    def calculate_improvement_metrics(self, baseline_kpis, optimized_kpis):
        """
        Compare performance before and after optimization
        """
        if not baseline_kpis or not optimized_kpis:
            return {}
            
        improvements = {}
        
        # Punctuality improvement
        improvements['punctuality_improvement'] = optimized_kpis['punctuality_rate'] - baseline_kpis['punctuality_rate']
        
        # Delay reduction
        improvements['delay_reduction'] = baseline_kpis['average_delay_minutes'] - optimized_kpis['average_delay_minutes']
        
        # Throughput improvement
        improvements['throughput_improvement'] = optimized_kpis['throughput_trains_per_hour'] - baseline_kpis['throughput_trains_per_hour']
        
        # Utilization improvement
        improvements['utilization_improvement'] = optimized_kpis['track_utilization_percent'] - baseline_kpis['track_utilization_percent']
        
        return improvements