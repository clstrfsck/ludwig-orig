{#if turbop}
unit version;

interface
uses value;

implementation

begin
{#endif}

{#if debug}
  ludwig_version :=
    'X4.1-048                       ';
{#else}
  ludwig_version :=
    'V4.1-048                       ';
{#endif}

{#if turbop}
end.
{#endif}
