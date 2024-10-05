unit caMidiMac;

interface

uses
  Classes, SysUtils, MacOsAll, caMidiIntf, caMidiTypes, caDbg;

type
  TcaMidiMac = class(TInterfacedObject, IcaMidiInterface)
  private
    function CFStringToStr(AString: CFStringRef): string;
    function SelectDevice(Index: integer): MIDIEndpointRef;
    procedure SendMidiPacket(OutputPort: longword; Device: MIDIEndpointRef; Packet: MIDIPacket; Errors: TStrings);
  protected
    function CreateMidiClient(Errors: TStrings): longword;
    function CreateMidiInputPort(MidiClient: longword; Errors: TStrings): longword;
    function CreateMidiOutputPort(MidiClient: longword; Errors: TStrings): longword;
    procedure GetDevices(InOut: TcaMidiInOut; Devices: TStrings);
    procedure SendCC(DeviceIndex, OutputPort: longword; Channel, CC: Byte; Errors: TStrings);
    procedure SendPGM(DeviceIndex, OutputPort: longword; Channel, PGM: Byte; Errors: TStrings);
  end;

implementation

function TcaMidiMac.CFStringToStr(AString: CFStringRef): string;
var
  Index: integer;
  Uni: UniChar;
begin
  if AString = nil then
  begin
    Result := '';
    Exit;
  end;
  Result := '';
  for Index := 0 to CFStringGetLength(AString) - 1 do
  begin
    Uni := CFStringGetCharacterAtIndex(AString, Index);
    Result := Result + Chr(Uni);
  end;
  Result := AnsiToUtf8(Result);
end;

function TcaMidiMac.CreateMidiClient(Errors: TStrings): longword;
var
  Stat: OSStatus;
begin
  Stat := MIDIClientCreate(CFSTR('MIDI CLIENT'), nil, nil, Result);
  if (Stat <> noErr) then
    Errors.Add('Error creating MIDI client: ' + GetMacOSStatusErrorString(Stat) + '  ' + GetMacOSStatusCommentString(Stat));
end;

function TcaMidiMac.CreateMidiInputPort(MidiClient: longword; Errors: TStrings): longword;
var
  Stat: OSStatus;
begin
  Stat := MIDIInputPortCreate(MidiClient, CFSTR('Input'), nil, nil, Result);
  if (Stat <> noErr) then
    Errors.Add('Error creating MIDI input port: ' + GetMacOSStatusErrorString(Stat) + '  ' + GetMacOSStatusCommentString(Stat));
end;

function TcaMidiMac.CreateMidiOutputPort(MidiClient: longword; Errors: TStrings): longword;
var
  Stat: OSStatus;
begin
  Stat := MIDIOutputPortCreate(MidiClient, CFSTR('Output'), Result);
  if Stat <> noErr then
    Errors.Add('Error creating MIDI output port: ' + GetMacOSStatusErrorString(Stat) + '  ' + GetMacOSStatusCommentString(Stat));
end;

procedure TcaMidiMac.GetDevices(InOut: TcaMidiInOut; Devices: TStrings);
var
  Count, Index: integer;
  Source: MIDIEndpointRef;
  PDevName: CFStringRef;
  DevName: string;
begin
  Devices.Clear;
  Count := specialize IfThen<integer>(InOut = ioIn, MIDIGetNumberOfSources, MIDIGetNumberOfDestinations);
  if Count > 0 then
  begin
    for Index := 0 to Count - 1 do
    begin
      Source := specialize IfThen<MIDIEndpointRef>(InOut = ioIn, MIDIGetSource(Index), MIDIGetDestination(Index));
      MIDIObjectGetStringProperty(Source, kMIDIPropertyName, PDevName);
      DevName := CFStringToStr(PDevName);
      if DevName <> '' then
        Devices.Add(DevName);
    end;
  end;
end;

function TcaMidiMac.SelectDevice(Index: integer): MIDIEndpointRef;
begin
  Result := MIDIGetDestination(Index);
end;

procedure TcaMidiMac.SendMidiPacket(OutputPort: longword; Device: MIDIEndpointRef; Packet: MIDIPacket; Errors: TStrings);
var
  Stat: OSStatus;
  PacketList: MIDIPacketList;
begin
  // Build packetlist
  PacketList.numPackets := 1;
  PacketList.packet[0] := Packet;
  Stat := MIDISend(OutputPort, Device, PacketList);
  if Stat <> noErr then
    Errors.Add('Error sending MIDI message: ' + GetMacOSStatusErrorString(Stat) + '  ' + GetMacOSStatusCommentString(Stat));
end;

procedure TcaMidiMac.SendCC(DeviceIndex, OutputPort: longword; Channel, CC: Byte; Errors: TStrings);
var
  Device: MIDIEndpointRef;
  Packet: MIDIPacket;
begin
  Device := SelectDevice(DeviceIndex);
  if Device <> 0 then
  begin
    // Build packet
    Packet.TimeStamp := 0; // Send immediately
    Packet.length := 3;
    Packet.Data[0] := $B0 or (Channel and $0F); // CC status
    Packet.Data[1] := 0;  // CC number (0 in this case)
    Packet.Data[2] := CC;
    // Send MIDI data
    SendMidiPacket(OutputPort, Device, Packet, Errors);
  end
  else
    Errors.Add('No MIDI Destination available');
end;

procedure TcaMidiMac.SendPGM(DeviceIndex, OutputPort: longword; Channel, PGM: Byte; Errors: TStrings);
var
  Device: MIDIEndpointRef;
  Packet: MIDIPacket;
begin
  Device := SelectDevice(DeviceIndex);
  if Device <> 0 then
  begin
    // Build packet
    Packet.TimeStamp := 0; // Send immediately
    Packet.length := 2;
    Packet.Data[0] := $C0 or (Channel and $0F);
    Packet.Data[1] := PGM;
    // Send MIDI data
    SendMidiPacket(OutputPort, Device, Packet, Errors);
  end
  else
    Errors.Add('No MIDI Destination available');
end;

end.
