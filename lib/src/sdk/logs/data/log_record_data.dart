import 'package:meta/meta.dart';
import 'package:opentelemetry/api.dart';
import 'package:opentelemetry/sdk.dart' as sdk;
import 'package:opentelemetry/src/api/logs/log_record.dart';
import 'package:opentelemetry/src/experimental_api.dart' as api;
import 'package:opentelemetry/src/sdk/common/attributes.dart';
import 'package:opentelemetry/src/sdk/logs/log_record_limits.dart';

Attributes _convertListAttrs(List<Attribute> attrs) {
  return Attributes.empty()..addAll(attrs);
}

extension _AttributesRepr on Attributes {
  Map<String, dynamic> get attributesRepr {
    final res = <String, dynamic>{};
    for (final key in keys) {
      res[key] = get(key);
    }
    return res;
  }
}

extension _InstrumentationScopeRepr on sdk.InstrumentationScope {
  Map<String, dynamic> get instrumentationScopeRepr {
    return {
      'name': name,
      'version': version,
      'schema_url': schemaUrl,
      'attributes': _convertListAttrs(attributes).attributesRepr,
    };
  }
}

class LogRecordData extends api.LogRecord {
  LogRecordLimits limits;
  sdk.Resource resource;
  sdk.InstrumentationScope instrumentationScope;
  int _droppedAttributes = 0;

  int get droppedAttributes => _droppedAttributes;

  Attributes get attributesCollection => _convertListAttrs(attributes);

  @override
  set attributes(List<Attribute> value) {
    attributes.clear();
    value.forEach(addAttribute);
  }

  @protected
  LogRecordData(
      super.timestamp,
      super.observedTimestamp,
      super.spanContext,
      super.severityNumber,
      super.severityText,
      super.body,
      super.attributes,
      this.limits,
      this.resource,
      this.instrumentationScope);

  LogRecordData.from(sdk.Resource resource,
      sdk.InstrumentationScope instrumentationScope, LogRecord logRecord)
      : this(
            logRecord.timestamp,
            logRecord.observedTimestamp,
            logRecord.spanContext,
            logRecord.severityNumber,
            logRecord.severityText,
            logRecord.body,
            logRecord.attributes,
            LogRecordLimits.unset(),
            resource,
            instrumentationScope);
  
  LogRecordData.copy(LogRecordData logRecordData): this(
    logRecordData.timestamp,
    logRecordData.observedTimestamp,
    logRecordData.spanContext,
    logRecordData.severityNumber,
    logRecordData.severityText,
    logRecordData.body,
    logRecordData.attributes,
    logRecordData.limits,
    logRecordData.resource,
    logRecordData.instrumentationScope
  );

  LogRecordData withLimits(LogRecordLimits limits) {
    this.limits = limits;
    return LogRecordData.copy(this);
  }

  @override
  void addAttribute(Attribute attr) {
    if (limits.attributeCountLimit != -1 && attributes.length >= limits.attributeCountLimit) {
      _droppedAttributes++;
      return;
    }
    attributes.add(limits.applyValueLengthLimit(attr));
  }


  Map<String, dynamic> toJson() {
    return {
      'timestamp': timestamp,
      'observedTimestamp': observedTimestamp,
      'traceId': spanContext.traceId,
      'spanId': spanContext.spanId,
      'traceFlags': spanContext.traceFlags,
      'severityNumber': severityNumber,
      'severityText': severityText,
      'body': body,
      'attributes': attributesCollection.attributesRepr,
      'resource': resource.attributes.attributesRepr,
      'instrumentationScope': instrumentationScope.instrumentationScopeRepr,
      'droppedAttributes': _droppedAttributes,
    };
  }
}



