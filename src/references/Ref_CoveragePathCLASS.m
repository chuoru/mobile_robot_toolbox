classdef Ref_CoveragePathCLASS
    properties
        % Params
        R = 20; 
        tMAX;
        dt;
        % States
        x;
        dxdt;
        ddxddt;
        % Input
        u;
        check;
    end

    % Private Properties
    properties (SetAccess = private, GetAccess = private)
        model;        % A model object
    end
    
    
    methods
        function obj = Ref_CoveragePathCLASS(model)
            %CTRL_BASECLASS Construct an instance of this class
            %   Detailed explanation goes here
            obj.model = model;
        end

        function obj = Generate(obj)
            %LE Summary of this function goes here
            %   Detailed explanation goes here
            t = linspace(0, obj.tMAX, (1/obj.dt) * obj.tMAX); % should take 60s to complete with 20 Hz sampling rate
            v = 2; % m/s

            obj.x = [];
            obj.dxdt = [];
            obj.ddxddt = [];

            for index=1:length(t)/3
                [x_, dxdt_, ddxddt_] = obj.GenerateStraightLine(v, [0;0;0], t(index));

                obj.x = [obj.x, x_];

                obj.dxdt = [obj.dxdt, dxdt_];

                obj.ddxddt = [obj.ddxddt, ddxddt_];
            end
                    
            for index=1:length(t)/3
                [x_, dxdt_, ddxddt_] = obj.GenerateClockwiseHalfCircle([v*length(t)*obj.dt/3; 0; 0], obj.R, t(index));

                obj.x = [obj.x, x_];

                obj.dxdt = [obj.dxdt, dxdt_];

                obj.ddxddt = [obj.ddxddt, ddxddt_];
            end


            for index=1:length(t)/3
                [x_, dxdt_, ddxddt_] = obj.GenerateStraightLine(-v,[v*length(t)*obj.dt/3; 2*obj.R; -pi/2],t(index));

                obj.x = [obj.x, x_];

                obj.dxdt = [obj.dxdt, dxdt_];

                obj.ddxddt = [obj.ddxddt, ddxddt_];
            end

            
            if isa(obj.model, 'Mdl_BicycleCLASS')
                v = sqrt(obj.dxdt(1, :).^2 + obj.dxdt(2, :).^2);

                delta = atan(obj.model.length_base * (obj.ddxddt(2, :) .* obj.dxdt(1, :) - obj.ddxddt(1, :) .* obj.dxdt(2, :)) ./ (v.^3));

                ddeltadt = zeros(1, length(t));

                for index = 1:length(t)-1
                    ddeltadt(1, index) = (delta(1, index+1) - delta(1, index)) / obj.dt; 
                end

                obj.u = [v; ddeltadt]; 

            else
                dthetadt = (obj.ddxddt(2, :) .* obj.dxdt(1, :) - obj.ddxddt(1, :) .* obj.dxdt(2, :)) ./ (obj.dxdt(1, :).^2 + obj.dxdt(2, :).^2);

                v_r = obj.model.distance * dthetadt + sqrt(obj.dxdt(1, :).^2 + obj.dxdt(2, :).^2);
                v_l = -obj.model.distance * dthetadt + sqrt(obj.dxdt(1, :).^2 + obj.dxdt(2, :).^2);

                obj.u = [v_r; v_l];

                obj.check = [dthetadt; sqrt(obj.dxdt(1, :).^2 + obj.dxdt(2, :).^2)];
            end
        end
    end

    methods(Static)
        function [x, dxdt, ddxddt] = GenerateStraightLine(v, x0, t)
            x      = x0 + [v * t; 0; 0];

            dxdt   = [v; 0];

            ddxddt = [0; 0];
        end

        function [x, dxdt, ddxddt] = GenerateClockwiseHalfCircle(x0, R, t)
            x      = [x0(1); R; x0(3)] + [-R*cos(pi/2 + pi/R*t); -R*sin(pi/2 + pi/R*t); pi/R*t];

            dxdt   = [R * (pi/R) * sin(pi/2 + pi/R*t)        ; -R * (pi/R) * cos(pi/2 + pi/R*t)];

            ddxddt = [R * (pi/R) * (pi/R) * cos(pi/2 + pi/R*t); R * (pi/R) * (pi/R) * sin(pi/2 + pi/R*t)];
        end
        
    end
end



 