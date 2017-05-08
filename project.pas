uses GraphABC,ABCObjects;
const
  ScaleX = 80;
  ScaleY = 25;
  Gravity = 2; 
type
  
  GameObject = class(RectangleABC)
  public 
  end;
  
  Solidable = interface
    function isOnTopOfGameObject(t:GameObject):boolean;
  end;
  
  Gravable = interface(Solidable)
    property isGrounded:boolean read write;
    procedure ApplyGravity;
    procedure Landing(on_y:integer);
  end;
var
  solidObjects := new List<GameObject>;
  gravableObjects:= new List<GameObject>;
  
  //Клавиши
  kLeftKey : boolean;
  kRightKey : boolean;
  kSpaceKey : boolean;
type
  
  Hero = class(GameObject, Gravable)
  private
    grounded:boolean;
  public 
    velocity: integer;
    function isOnTopOfGameObject(l:GameObject):boolean;
    begin
      result:= (l.PtInside(self.Center.X-self.Width div 2,  self.Center.Y - self.Height div 2 - 15)) 
       or (l.PtInside(self.Center.X,  self.Center.Y - self.Height div 2 - 15))
       or (l.PtInside(self.Center.X+self.Width div 2,  self.Center.Y - self.Height div 2 - 15));
    end;
    procedure ApplyGravity();
    begin
      self.dy -= Gravity;
    end;
    procedure Landing(y:integer);
    begin
      self.dy:=0;  
      self.MoveTo(self.Position.X, y + self.Height);
      self.grounded:= true;
    end;
    procedure Jump();
    begin
      self.dy:=20;
      self.grounded:=false;
    end;
    constructor Create(x,y:integer);
    begin
       inherited Create(x, y, 50, 50,GColor.Beige);
       velocity:=1;
    end;
    property isGrounded: boolean read grounded write grounded;
    
  end;
  
  Enemy=class(GameObject, Gravable)
  private
   grounded:Boolean;
  public
   velocity:Integer;
   function isOnTopOfGameObject(l:GameObject):boolean;
     begin
       result:= (l.PtInside(self.Center.X-self.Width div 2,  self.Center.Y - self.Height div 2 - 15)) 
        or (l.PtInside(self.Center.X,  self.Center.Y - self.Height div 2 - 15))
        or (l.PtInside(self.Center.X+self.Width div 2,  self.Center.Y - self.Height div 2 - 15));
     end;      
   procedure ApplyGravity();
    begin
     self.dy -= Gravity;
    end;
   procedure Landing(y:integer);
    begin
     self.dy:=0;  
     self.MoveTo(self.Position.X, y + self.Height);
     self.grounded:= true;
    end;
   procedure Jump();
    begin
      self.dy:=20;
      self.grounded:=false;
    end;
//   procedure Move();
   constructor Create(x,y:integer);
    begin
       inherited Create(x, y, 50, 50,GColor.Beige);
       velocity:=1;
    end;
   property isGrounded: boolean read grounded write grounded;
  end;
  
  Ground = class(GameObject, Solidable)
  public 
    function isOnTopOfGameObject(l:GameObject):boolean;
    begin
      result:=false;
    end;
    constructor Create(x,y,w,h:integer);
    begin
      inherited Create(x,y,w,h,GColor.Aqua);
    end;
  end;
  
var
  h: Hero;
  floor: Ground;
  e:Enemy;
 

procedure ApplyGravity();
var
  tmp: Gravable;
begin
  foreach var elem in gravableObjects do
  begin
    var gr:Gravable:=(elem as Gravable);
    if not gr.isGrounded then gr.ApplyGravity(); 
  end;
end;


procedure CheckCollisions();
var any_floor:boolean;
begin
  foreach var tested in gravableObjects do
  begin
    any_floor:=false;
    foreach var elem in solidObjects do
    begin
       var grav:Gravable:= (tested as Gravable);
       if grav.isOnTopOfGameObject(elem) then
       begin
        grav.Landing(elem.Position.Y);
        any_floor:=true;
       end;
 
    end;
    
    if not any_floor then (tested as Gravable).isGrounded:=false;
    
  end;
 
end;


/// Обработчик нажатия клавиши
procedure KeyDown(Key: integer);
begin
  case Key of
vk_Left:  kLeftKey := True;
vk_Right: kRightKey := True;
vk_Space: kSpaceKey := True;
  end;
end;

/// Обработчик отжатия клавиши
procedure KeyUp(Key: integer);
begin
  case Key of
vk_Left:  kLeftKey := False;
vk_Right: kRightKey := False;
vk_Space: kSpaceKey := False;
  end;
end;

procedure CheckControls();
var moveX:integer;
begin
  moveX:=0;
  if (kLeftKey) then dec(moveX);
  if (kRightKey) then inc(moveX);
  h.dx := moveX * h.velocity;
  if (kSpaceKey) and (h.grounded) then h.jump();
end;

begin

   //Настройка координат
  Coordinate.SetMathematic();
  Coordinate.SetOrigin(0, Window.Height);
  
  //Персонаж
  h := new Hero(10,200);
  h.velocity := 10;
  solidObjects.Add(h);
  gravableObjects.Add(h);
  
  //Enemy
  e:=new Enemy(30,200);
  e.velocity:=0;
  solidObjects.Add(e);
  gravableObjects.Add(e);
  
  //Платформы
  solidObjects.Add(new Ground(0,0,Window.Width,50));
  solidObjects.Add(new Ground(300,100,200,50));
  solidObjects.Add(new Ground(100,300,100,50));
  solidObjects.Add(new Ground(200,200,50,50));
  
  //Обрабочики клавиш
  OnKeyDown := KeyDown;
  OnKeyUp := KeyUp;
  
  ClearWindow();
  
  while True do
  begin
    LockDrawingObjects;
    CheckCollisions();
    ApplyGravity();
    CheckControls(); 
    for i:integer:= 0 to Objects.Count - 1 do
      Objects[i].Move();
      
    UnLockDrawingObjects;
    Sleep(10);
    //Sleep(10);
    // Redraw;
    
  end;
  
end.